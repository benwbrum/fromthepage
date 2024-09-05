require 'spec_helper'
require 'faker'

RSpec.describe Transkribus::TranskribusPageProcessingTask, type: :model do
  let(:user) { create(:user, email: Faker::Internet.unique.email, login: Faker::Internet.unique.username) }
  let(:collection) { create(:collection, owner_user_id: user.id) }
  let(:work) { create(:work, collection: collection) }
  let(:page) { create(:page, work: work) }
  let(:ai_job) { create(:ai_job, user: user, collection: collection, work: work, page: page) }
  let(:page_processing_job) { create(:page_processing_job, page: page, ai_job: ai_job) }
  let(:task) { described_class.new(page_processing_job: page_processing_job) }

  describe '#process_page' do
    context 'when the status is QUEUED' do
      before do
        ai_job.parameters = { described_class.name => { 'model_id' => 5 } }
        ai_job.save!
        task.status = PageProcessingJob::Status::QUEUED
      end

      
      context 'when submit_processing_request returns a response with HTTP code 200' do
        it 'launching the processing job changes the status to WAITING' do
          response =  instance_double(HTTParty::Response, code: 200, body: '{"process_id": "32"}', parsed_response: { 'process_id' => '32' })
          allow(task).to receive(:authorized_transkribus_request).and_return(response)
          expect(task).not_to receive(:check_status)
          expect(task).not_to receive(:fetch_alto)
          task.process_page
          expect(task.status).to eq(PageProcessingJob::Status::WAITING)
        end
      end

      context 'when submit_processing_request returns a response with HTTP code 429' do
        it 'sets the status to FAILED' do
          response =  instance_double(HTTParty::Response, code: 429)
          allow(task).to receive(:authorized_transkribus_request).and_return(response)
          expect(task).not_to receive(:check_status)
          expect(task).not_to receive(:fetch_alto)
          task.process_page
          expect(task.status).to eq(PageProcessingJob::Status::FAILED)
        end
      end

      context 'when submit_processing_request returns a response with a different HTTP code' do
        it 'sets the status to FAILED' do
          response =  instance_double(HTTParty::Response, code: 500)
          allow(task).to receive(:authorized_transkribus_request).and_return(response)
          expect(task).not_to receive(:check_status)
          expect(task).not_to receive(:fetch_alto)
          task.process_page
          expect(task.status).to eq(PageProcessingJob::Status::FAILED)
        end


        it 'saves the error details' do
          response =  instance_double(HTTParty::Response, code: 500, parsed_response: { 'error' => 'Internal server error' })
          allow(task).to receive(:authorized_transkribus_request).and_return(response)
          expect(task).not_to receive(:check_status)
          expect(task).not_to receive(:fetch_alto)
          task.process_page
          expect(task.details['error']).to eq(response.to_json)
        end
      end
    end

    context 'when the status is WAITING' do
      context 'when authorized_transkribus_request returns a response with HTTP code 200 and contents FINISHED' do
        it 'fetches the ALTO XML' do
          task.status = PageProcessingJob::Status::WAITING
          response =  instance_double(HTTParty::Response, code: 200, parsed_response: { 'status' => 'FINISHED' })
          allow(task).to receive(:authorized_transkribus_request).and_return(response)
          expect(task).to receive(:fetch_alto)
          task.process_page
        end



        it 'sets the status to COMPLETED' do
          task.status = PageProcessingJob::Status::WAITING
          response =  instance_double(HTTParty::Response, code: 200, parsed_response: { 'status' => 'FINISHED' })
          allow(task).to receive(:authorized_transkribus_request).and_return(response)
          allow(task).to receive(:fetch_alto)
          task.process_page
          expect(task.status).to eq(PageProcessingJob::Status::COMPLETED)
        end

      end
      context 'when authorized_transkribus_request returns a response with HTTP code 200 and contents not FINISHED' do
        it 'sets the status to WAITING' do
          task.status = PageProcessingJob::Status::WAITING
          response =  instance_double(HTTParty::Response, code: 200, parsed_response: { 'status' => 'RUNNING' })
          allow(task).to receive(:authorized_transkribus_request).and_return(response)
          expect(task).not_to receive(:fetch_alto)
          task.process_page
          expect(task.status).to eq(PageProcessingJob::Status::WAITING)
        end
      end

    end


    context 'when the status is RUNNING' do
      before do
        task.status = PageProcessingJob::Status::RUNNING
      end

      it 'does nothing' do
        expect(task).not_to receive(:launch_processing_job)
        expect(task).not_to receive(:check_status)
        expect(task).not_to receive(:fetch_alto)
        task.process_page
        expect(task.status).to eq(PageProcessingJob::Status::RUNNING)
      end
    end

    context 'when the status is FAILED' do
      before do
        task.status = PageProcessingJob::Status::FAILED
      end

      it 'does nothing' do
        expect(task).not_to receive(:launch_processing_job)
        expect(task).not_to receive(:check_status)
        expect(task).not_to receive(:fetch_alto)
        task.process_page
        expect(task.status).to eq(PageProcessingJob::Status::FAILED)
      end
    end

    context 'when the status is WAITING' do
      before do
        task.status = PageProcessingJob::Status::WAITING
        # allow(task).to receive(:check_status).and_return(Transkribus::Response::READY)
        allow(task).to receive(:fetch_alto)
      end

      it 'checks the job status and performs the corresponding actions' do
        response =  instance_double(HTTParty::Response, code: 200, parsed_response: { 'status' => 'FINISHED' })
        allow(task).to receive(:authorized_transkribus_request).and_return(response)

        expect(task).to receive(:fetch_alto)
        task.process_page
        expect(task.status).to eq(PageProcessingJob::Status::COMPLETED)
      end
    end
  end

  # describe '#launch_processing_job' do
  #   let(:model_id) { '123' }
  #   let(:submit_response) { double(code: 200, parsed_response: { 'processId' => '456' }) }

  #   before do
  #     allow(task).to receive(:authorized_transkribus_request).and_return(submit_response)
  #   end

  #   it 'submits the processing request and updates the task details and status' do
  #     expect(task).to receive(:authorized_transkribus_request).and_return(submit_response)
  #     task.launch_processing_job
  #     expect(task.details['process_id']).to eq('456')
  #     expect(task.status).to eq(Status::WAITING)
  #   end

  #   context 'when the submit response code is not 200' do
  #     let(:submit_response) { double(code: 429) }

  #     it 'handles the error and updates the task details and status' do
  #       expect(task).to receive(:authorized_transkribus_request).and_return(submit_response)
  #       task.launch_processing_job
  #       expect(task.details['error']).to eq(submit_response.to_json)
  #       expect(task.status).to eq(Status::FAILED)
  #     end
  #   end
  # end

  # describe '#check_status' do
  #   let(:process_id) { '456' }
  #   let(:status_response) { double(code: 200, parsed_response: { 'status' => 'READY' }) }

  #   before do
  #     allow(task).to receive(:authorized_transkribus_request).and_return(status_response)
  #   end

  #   it 'checks the processing status and returns the corresponding response' do
  #     expect(task).to receive(:authorized_transkribus_request).and_return(status_response)
  #     expect(task.check_status).to eq(Response::READY)
  #   end

  #   context 'when the status response code is not 200' do
  #     let(:status_response) { double(code: 404) }

  #     it 'handles the error and returns the corresponding response' do
  #       expect(task).to receive(:authorized_transkribus_request).and_return(status_response)
  #       expect(task.check_status).to eq(Response::READY)
  #     end
  #   end

  #   context 'when the status is CANCELED' do
  #     let(:status_response) { double(code: 200, parsed_response: { 'status' => 'CANCELED' }) }

  #     it 'handles the cancellation and returns nil' do
  #       expect(task).to receive(:authorized_transkribus_request).and_return(status_response)
  #       expect(task.check_status).to be_nil
  #     end
  #   end
  # end

  # describe '#fetch_alto' do
  #   let(:process_id) { '456' }
  #   let(:alto_response) { double(code: 200, body: '<alto>...</alto>') }

  #   before do
  #     allow(task).to receive(:authorized_transkribus_request).and_return(alto_response)
  #   end

  #   it 'fetches the ALTO XML and saves it to the page' do
  #     expect(task).to receive(:authorized_transkribus_request).and_return(alto_response)
  #     expect(page).to receive(:alto_xml=).with('<alto>...</alto>')
  #     expect(page).to receive(:save!)
  #     task.fetch_alto
  #   end
  # end
end