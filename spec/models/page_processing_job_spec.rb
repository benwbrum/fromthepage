require 'spec_helper'
require 'faker'

RSpec.describe PageProcessingJob, type: :model do
  describe '#create_tasks' do
    let(:user) { create(:user, email: Faker::Internet.unique.email, login: Faker::Internet.unique.username) }
    let(:collection) { create(:collection, owner_user_id: user.id) }
    let(:work) { create(:work, collection: collection) }
    let(:page) { create(:page, work: work) }
    let(:ai_job) { create(:ai_job, user: user, collection: collection, work: work, page: page) }
    let(:page_processing_job) { create(:page_processing_job, ai_job: ai_job, page: page) }

    context 'when ai job type is HTR' do
      before do
        ai_job.update(job_type: AiJob::JobType::HTR)
      end

      it 'creates a TranskribusPageProcessingTask' do
        expect(page_processing_job.page_processing_tasks.where(type: 'Transkribus::TranskribusPageProcessingTask').count).to eq(1)
        expect(page_processing_job.page_processing_tasks.where(type: 'OpenAi::AiTextPageProcessingTask').count).to eq(0)
      end
    end

    context 'when ai job type is AI_TEXT' do
      before do
        ai_job.update(job_type: AiJob::JobType::AI_TEXT)
      end

      it 'creates an AiTextPageProcessingTask' do
        expect(page_processing_job.page_processing_tasks.where(type: 'Transkribus::TranskribusPageProcessingTask').count).to eq(0)
        expect(page_processing_job.page_processing_tasks.where(type: 'OpenAi::AiTextPageProcessingTask').count).to eq(1)
    end

    context 'when ai job type is HTR_AND_AI_TEXT' do
      before do
        ai_job.update(job_type: AiJob::JobType::HTR_AND_AI_TEXT)
      end

      it 'creates an AiTextPageProcessingTask' do
        expect(page_processing_job.page_processing_tasks.where(type: 'Transkribus::TranskribusPageProcessingTask').count).to eq(1)
        expect(page_processing_job.page_processing_tasks.where(type: 'OpenAi::AiTextPageProcessingTask').count).to eq(1)
      end
    end
  end

  describe '#run_tasks' do
    let(:user) { create(:user, email: Faker::Internet.unique.email, login: Faker::Internet.unique.username) }
    let(:collection) { create(:collection, owner_user_id: user.id) }
    let(:work) { create(:work, collection: collection) }
    let(:page) { create(:page, work: work) }
    let(:ai_job) { create(:ai_job, user: user, collection: collection, work: work, page: page, job_type: 'other') }
    let(:page_processing_job) { create(:page_processing_job, ai_job: ai_job, page: page) }

    context 'when status is COMPLETED' do
      before do
        page_processing_job.update(status: PageProcessingJob::Status::COMPLETED)
      end

      it 'does not run any tasks' do
        expect(page_processing_job).not_to receive(:save)
        page_processing_job.run_tasks
      end
    end

    context 'when status is FAILED' do
      before do
        page_processing_job.update(status: PageProcessingJob::Status::FAILED)
      end

      it 'does not run any tasks' do
        expect(page_processing_job).not_to receive(:save)
        page_processing_job.run_tasks
      end
    end

    context 'when status is RUNNING' do
      before do
        page_processing_job.update(status: PageProcessingJob::Status::RUNNING)
      end

      it 'does not run any tasks' do
        expect(page_processing_job).not_to receive(:save)
        page_processing_job.run_tasks
      end
    end

    context 'when status is QUEUED' do
      let(:task1) { create(:page_processing_task, status: PageProcessingTask::Status::COMPLETED, page_processing_job: page_processing_job, position: 1) }
      let(:task2) { create(:page_processing_task, status: PageProcessingTask::Status::WAITING, page_processing_job: page_processing_job, position: 3) }

      before do
        page_processing_job.update(status: PageProcessingJob::Status::QUEUED)
      end

      it 'runs the tasks in the correct order' do
        expect(task1).not_to receive(:process_page)
        expect(task2).not_to receive(:process_page)
        print task2.id
        page_processing_job.run_tasks
      end

    #   it 'updates status to FAILED if any task fails' do
    #     allow(task2).to receive(:process_page).and_return(nil)
    #     expect(page_processing_job).to receive(:save)
    #     page_processing_job.run_tasks
    #     expect(page_processing_job.status).to eq(PageProcessingJob::Status::FAILED)
    #   end

    #   it 'updates status to WAITING if any task is waiting' do
    #     allow(task3).to receive(:process_page).and_return(nil)
    #     expect(page_processing_job).to receive(:save)
    #     page_processing_job.run_tasks
    #     expect(page_processing_job.status).to eq(PageProcessingJob::Status::WAITING)
    #   end

    #   it 'duplicates and runs the task if it is in RETRY status' do
    #     expect(task4).to receive(:dup).and_return(task4)
    #     expect(task4).to receive(:save)
    #     expect(task4).to receive(:process_page).and_return(nil)
    #     page_processing_job.run_tasks
    #   end
      end
    end
  end
end