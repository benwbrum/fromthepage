require 'rails_helper'

RSpec.describe PageVersionsHelper, type: :helper do
  describe '#render_status_icon' do
    context 'with valid status types' do
      it 'renders icon with correct translation for review status' do
        result = helper.render_status_icon('page_version_status_review')

        expect(result).to include('page_version_status_review-icon.svg')
        expect(result).to include('alt="review Icon"')
        expect(result).to include('title="review"')
      end

      it 'renders icon with correct translation for incomplete status' do
        result = helper.render_status_icon('page_version_status_incomplete')

        expect(result).to include('page_version_status_incomplete-icon.svg')
        expect(result).to include('alt="incomplete Icon"')
        expect(result).to include('title="incomplete"')
      end

      it 'renders icon with correct translation for transcribed status' do
        result = helper.render_status_icon('page_version_status_transcribed')

        expect(result).to include('page_version_status_transcribed-icon.svg')
        expect(result).to include('alt="transcribed Icon"')
        expect(result).to include('title="transcribed"')
      end

      it 'renders icon with correct translation for blank status' do
        result = helper.render_status_icon('page_version_status_blank')

        expect(result).to include('page_version_status_blank-icon.svg')
        expect(result).to include('alt="blank Icon"')
        expect(result).to include('title="blank"')
      end
    end

    context 'with unknown status' do
      it 'renders custom icon with original status as title' do
        result = helper.render_status_icon('unknown_status')

        expect(result).to include('custom-icon.svg')
        expect(result).to include('title="unknown_status"')
      end
    end

    context 'translation behavior' do
      it 'uses t() helper method with scope instead of I18n.t direct call' do
        # This test verifies that the helper uses the Rails t() method
        # which should properly resolve the scope
        expect(helper).to receive(:t).with('page_version_status_review', scope: 'page_version.show', default: 'page_version_status_review').and_return('review')

        result = helper.render_status_icon('page_version_status_review')
        expect(result).to include('title="review"')
      end
    end
  end
end
