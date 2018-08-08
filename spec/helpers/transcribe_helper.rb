require 'spec_helper'

RSpec.describe TranscribeHelper, :type => :helper do
    describe "#subject_context" do
      it "returns the matched title and three lines on either side as default" do
        excerpt = "One\nTwo\nThree\nFour\n[[Match]]\nFive\nSix\nSeven\nEight"
        expected = "Two\nThree\nFour\n<b>[[Match]]</b>\nFive\nSix\nSeven"

        expect(helper.subject_context(excerpt, "Match")).to eq(expected)
      end
      it "returns the matched title and one line on either side" do
        excerpt = "One\nTwo\nThree\nFour\n[[Match]]\nFive\nSix\nSeven\nEight"
        expected = "Four\n<b>[[Match]]</b>\nFive"

        expect(helper.subject_context(excerpt, "Match", 1)).to eq(expected)
      end
      it "returns the matched title with radius 0" do
        excerpt = "One\nTwo\nThree\nFour\n[[Match]]\nFive\nSix\nSeven\nEight"
        expected = "<b>[[Match]]</b>"
        
        expect(helper.subject_context(excerpt, "Match", 0)).to eq(expected)
      end
      it "returns the matched title with invalid parameter" do
        excerpt = "One\nTwo\nThree\nFour\n[[Match]]\nFive\nSix\nSeven\nEight"
        expected = "<b>[[Match]]</b>"
        
        expect(helper.subject_context(excerpt, "Match", -1)).to eq(expected)
      end
      it "returns the title if there's no match" do
        excerpt = "One\nTwo\nThree\nFour\n[[BADMATCH]]\nFive\nSix\nSeven\nEight"
        expected = "<b>Match</b>"
        
        expect(helper.subject_context(excerpt, "Match", -1)).to eq(expected)
      end
    end
  end