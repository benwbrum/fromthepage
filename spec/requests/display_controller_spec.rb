require 'spec_helper'

describe DisplayController do
  let(:owner) { User.find_by(owner: true) || create(:user, owner: true) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:pages) do
    (1..10).map do |i|
      create(:page, work: work, position: i, title: "Page #{i}")
    end
  end

  before do
    Current.user = owner
  end

  describe '#ai_text' do
    let(:page) { pages.first }
    let(:action_path) { collection_ai_text_page_path(owner, collection, work, page) }

    context 'when page has AI plaintext' do
      before do
        allow_any_instance_of(Page).to receive(:has_ai_plaintext?).and_return(true)
        allow_any_instance_of(Page).to receive(:ai_plaintext).and_return("AI generated text content")
      end

      it 'renders the AI text page' do
        get action_path

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:ai_text)
      end

      context 'with completed transcription' do
        before do
          page.status = :transcribed
          page.save!
          allow_any_instance_of(Page).to receive(:ai_accuracy_statistics).and_return({
            verbatim: { cer: 5.0, wer: 10.0 },
            text_only: { cer: 3.0, wer: 8.0 }
          })
        end

        it 'calculates and provides accuracy statistics' do
          get action_path

          expect(assigns(:ai_accuracy_stats)).not_to be_nil
          expect(assigns(:ai_accuracy_stats)[:verbatim]).to have_key(:cer)
          expect(assigns(:ai_accuracy_stats)[:verbatim]).to have_key(:wer)
        end
      end

      context 'without completed transcription' do
        before do
          page.status = :incomplete
          page.save!
        end

        it 'does not provide accuracy statistics' do
          get action_path

          expect(assigns(:ai_accuracy_stats)).to be_nil
        end
      end
    end

    context 'when page does not have AI plaintext' do
      before do
        allow_any_instance_of(Page).to receive(:has_ai_plaintext?).and_return(false)
      end

      it 'redirects to display page' do
        get action_path

        expect(response).to redirect_to(collection_display_page_path(owner, collection, work, page))
      end
    end
  end

  describe '#read_work' do
    let(:action_path) { collection_read_work_path(owner, collection, work) }

    context 'without page range' do
      it 'renders all pages' do
        get action_path

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:read_work)
        expect(assigns(:pages)).to be_present
        expect(assigns(:page_range_filter)).to be_falsy
        expect(assigns(:heading)).to eq('Pages')
      end
    end

    context 'with valid page range' do
      let(:action_path) { collection_read_work_with_range_path(owner, collection, work, '3-7') }

      it 'filters pages by range' do
        get action_path

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:read_work)
        expect(assigns(:page_range_filter)).to be_truthy
        expect(assigns(:start_page)).to eq(3)
        expect(assigns(:end_page)).to eq(7)
        expect(assigns(:heading)).to eq('Pages (3-7)')
      end
    end

    context 'with page range prefixed with "pp"' do
      let(:action_path) { collection_read_work_with_range_path(owner, collection, work, 'pp3-7') }

      it 'filters pages by range' do
        get action_path

        expect(response).to have_http_status(:ok)
        expect(assigns(:page_range_filter)).to be_truthy
        expect(assigns(:start_page)).to eq(3)
        expect(assigns(:end_page)).to eq(7)
        expect(assigns(:heading)).to eq('Pages (3-7)')
      end
    end

    context 'with page range prefixed with "p"' do
      let(:action_path) { collection_read_work_with_range_path(owner, collection, work, 'p3-7') }

      it 'filters pages by range' do
        get action_path

        expect(response).to have_http_status(:ok)
        expect(assigns(:page_range_filter)).to be_truthy
        expect(assigns(:start_page)).to eq(3)
        expect(assigns(:end_page)).to eq(7)
        expect(assigns(:heading)).to eq('Pages (3-7)')
      end
    end

    context 'with invalid page range format' do
      let(:action_path) { collection_read_work_with_range_path(owner, collection, work, 'invalid') }

      it 'ignores invalid range and works normally' do
        # This should not match our route constraint, so it won't reach the controller
        expect { get action_path }.to raise_error(ActionController::UrlGenerationError)
      end
    end

    context 'with invalid page range (start > end)' do
      let(:action_path) { collection_read_work_with_range_path(owner, collection, work, '7-3') }

      it 'handles invalid range gracefully' do
        get action_path

        expect(response).to have_http_status(:ok)
        expect(assigns(:page_range_filter)).to be_falsy
        expect(assigns(:heading)).to eq('Pages')
      end
    end

    context 'with page range and review filter' do
      let(:action_path) { collection_read_work_with_range_path(owner, collection, work, '3-7') }
      let(:params) { { needs_review: 'review' } }

      it 'applies both filters' do
        get action_path, params: params

        expect(response).to have_http_status(:ok)
        expect(assigns(:page_range_filter)).to be_truthy
        expect(assigns(:start_page)).to eq(3)
        expect(assigns(:end_page)).to eq(7)
        expect(assigns(:heading)).to eq('Pages That Need Review (3-7)')
      end
    end
  end

  describe '#parse_page_range' do
    let(:controller) { described_class.new }

    context 'with valid ranges' do
      it 'parses simple range' do
        result = controller.send(:parse_page_range, '3-7')
        expect(result).to eq([3, 7])
      end

      it 'parses range with pp prefix' do
        result = controller.send(:parse_page_range, 'pp3-7')
        expect(result).to eq([3, 7])
      end

      it 'parses range with p prefix' do
        result = controller.send(:parse_page_range, 'p3-7')
        expect(result).to eq([3, 7])
      end

      it 'parses single digit range' do
        result = controller.send(:parse_page_range, '1-2')
        expect(result).to eq([1, 2])
      end

      it 'parses multi-digit range' do
        result = controller.send(:parse_page_range, '15-25')
        expect(result).to eq([15, 25])
      end
    end

    context 'with invalid ranges' do
      it 'returns nil for empty string' do
        result = controller.send(:parse_page_range, '')
        expect(result).to be_nil
      end

      it 'returns nil for nil' do
        result = controller.send(:parse_page_range, nil)
        expect(result).to be_nil
      end

      it 'returns nil for invalid format' do
        result = controller.send(:parse_page_range, 'invalid')
        expect(result).to be_nil
      end

      it 'returns nil when start > end' do
        result = controller.send(:parse_page_range, '7-3')
        expect(result).to be_nil
      end

      it 'returns nil when start is 0' do
        result = controller.send(:parse_page_range, '0-5')
        expect(result).to be_nil
      end

      it 'returns nil for non-numeric values' do
        result = controller.send(:parse_page_range, 'a-b')
        expect(result).to be_nil
      end
    end
  end
end
