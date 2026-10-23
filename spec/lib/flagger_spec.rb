require 'spec_helper'

describe Flagger do
  before(:each) do
    # Reset class variables
    Flagger.class_variable_set(:@@denylist, nil)
    Flagger.class_variable_set(:@@allowlist, nil)

    # Set up denylist
    denylist_block = PageBlock.find_or_create_by(controller: 'admin', view: 'flag_denylist') do |pb|
      pb.html = "href\n.com\n.net"
    end
    denylist_block.html = "href\n.com\n.net"
    denylist_block.save!

    # Set up allowlist
    allowlist_block = PageBlock.find_or_create_by(controller: 'admin', view: 'flag_allowlist') do |pb|
      pb.html = "merriam-webster.com\nancestry.com\nfindagrave.com\nwikipedia.org\nbooks.google.com\nthefreedictionary.com\nnewspapers.com"
    end
    allowlist_block.html = "merriam-webster.com\nancestry.com\nfindagrave.com\nwikipedia.org\nbooks.google.com\nthefreedictionary.com\nnewspapers.com"
    allowlist_block.save!
  end

  describe '.check' do
    context 'with allowed domains' do
      it 'does not flag content with merriam-webster.com' do
        content = "Check the definition at https://www.merriam-webster.com/dictionary/word"
        result = Flagger.check(content)
        expect(result).to be_nil
      end

      it 'does not flag content with ancestry.com' do
        content = "Found on https://ancestry.com/search"
        result = Flagger.check(content)
        expect(result).to be_nil
      end

      it 'does not flag content with findagrave.com' do
        content = "See memorial at https://www.findagrave.com/memorial/12345"
        result = Flagger.check(content)
        expect(result).to be_nil
      end

      it 'does not flag content with wikipedia.org' do
        content = "More info at https://en.wikipedia.org/wiki/Something"
        result = Flagger.check(content)
        expect(result).to be_nil
      end

      it 'does not flag content with books.google.com' do
        content = "Available at https://books.google.com/books?id=12345"
        result = Flagger.check(content)
        expect(result).to be_nil
      end

      it 'does not flag content with thefreedictionary.com' do
        content = "Definition: https://www.thefreedictionary.com/word"
        result = Flagger.check(content)
        expect(result).to be_nil
      end

      it 'does not flag content with newspapers.com' do
        content = "Newspaper clipping: https://www.newspapers.com/clip/12345"
        result = Flagger.check(content)
        expect(result).to be_nil
      end
    end

    context 'with non-allowed domains' do
      it 'flags content with random .com domains' do
        content = "Check out https://spam-site.com for great deals"
        result = Flagger.check(content)
        expect(result).not_to be_nil
        expect(result).to include('spam-site.com')
      end

      it 'flags content with .net domains' do
        content = "Visit http://suspicious.net"
        result = Flagger.check(content)
        expect(result).not_to be_nil
      end

      it 'flags content with href attribute' do
        content = '<a href="http://badsite.com">Click here</a>'
        result = Flagger.check(content)
        expect(result).not_to be_nil
      end
    end

    context 'with nil content' do
      it 'returns nil for nil content' do
        result = Flagger.check(nil)
        expect(result).to be_nil
      end
    end

    context 'with clean content' do
      it 'returns nil for content without suspicious patterns' do
        content = "This is a clean transcription with no URLs or suspicious content"
        result = Flagger.check(content)
        expect(result).to be_nil
      end
    end

    context 'with mixed content' do
      it 'does not flag when allowed domain appears with denylist pattern' do
        content = "See https://en.wikipedia.org/wiki/Example.com for more info"
        result = Flagger.check(content)
        expect(result).to be_nil
      end

      it 'flags suspicious content even when followed by allowed domain reference' do
        content = "Visit http://badsite.com (not wikipedia.org)"
        result = Flagger.check(content)
        expect(result).not_to be_nil
      end
    end
  end

  describe '.initialize_denylist' do
    it 'loads the denylist from PageBlock' do
      Flagger.initialize_denylist
      denylist = Flagger.class_variable_get(:@@denylist)
      expect(denylist).to be_a(Array)
      expect(denylist).to include('href')
    end

    it 'handles missing PageBlock gracefully' do
      PageBlock.where(controller: 'admin', view: 'flag_denylist').delete_all
      Flagger.class_variable_set(:@@denylist, nil)
      Flagger.initialize_denylist
      denylist = Flagger.class_variable_get(:@@denylist)
      expect(denylist).to eq([])
    end
  end

  describe '.initialize_allowlist' do
    it 'loads the allowlist from PageBlock' do
      Flagger.initialize_allowlist
      allowlist = Flagger.class_variable_get(:@@allowlist)
      expect(allowlist).to be_a(Array)
      expect(allowlist).to include('merriam-webster\\.com')
    end

    it 'handles missing PageBlock gracefully' do
      PageBlock.where(controller: 'admin', view: 'flag_allowlist').delete_all
      Flagger.class_variable_set(:@@allowlist, nil)
      Flagger.initialize_allowlist
      allowlist = Flagger.class_variable_get(:@@allowlist)
      expect(allowlist).to eq([])
    end
  end
end
