require 'rails_helper'

RSpec.describe 'Task API' do
  before { host! 'api.taskmanager.dev' }

  # Create this moment '!'
  let!(:user) { create(:user) }
  let(:headers) do
    {
      'Accept' => 'application/vnd.taskmanager.v2',
      'Content-Type' => Mime[:json].to_s,
      'Authorization' => user.auth_token
    }
  end

  describe 'GET /tasks' do
    before do
      # Criate a list of tasks
      create_list(:task, 5, user_id: user.id)
      get '/tasks', params: {}, headers: headers
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end

    it 'returns 5 tasks from database' do
      expect(json_body[:data].count).to eq(5)
    end
  end

  describe 'GET /task/:id' do
    let(:task) { create(:task, user_id: user.id) }

    before { get "/tasks/#{task.id}", params: {}, headers: headers }

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end

    it 'returns json for task' do
      expect(json_body[:data][:attributes][:title]).to eq(task.title)
    end
  end

  describe 'POST /tasks' do
    before do
      post '/tasks', params: { task: task_params }.to_json, headers: headers
    end

    context 'when the params are valid' do
      # Creat hash object params
      let(:task_params) { attributes_for(:task) }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'saves the task in database' do
        expect(Task.find_by(title: task_params[:title])).not_to be_nil
      end

      it 'returns the json for created task' do
        expect(json_body[:data][:attributes][:title]).to eq(task_params[:title])
      end

      it 'assing the created task do the current user' do
        expect(json_body[:data][:attributes][:'user-id']).to eq(user.id)
      end

      context 'when the params are invalid' do
        let(:task_params) { attributes_for(:task, title: ' ') }

        it 'returns status code 422' do
          expect(response).to have_http_status(422)
        end

        it 'does not sabe task in the database' do
          expect(Task.find_by(title: task_params[:title])).to be_nil
        end

        it 'returs the json error for title' do
          expect(json_body[:errors]).to have_key(:title)
        end
      end
    end
  end

  describe 'PUT /tasks/:id' do
    let(:task) { create(:task, user_id: user.id) }
    before do
      put "/tasks/#{task.id}", params: { task: task_params }.to_json, headers: headers
    end

    context 'when the params are valid' do
      let(:task_params) { { title: 'New task title' } }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the json for updated task' do
        expect(json_body[:data][:attributes][:title]).to eq(task_params[:title])
      end

      it 'updates the task in the database' do
        expect(Task.find_by(title: task_params[:title])).not_to be_nil
      end
    end
    context 'when the params are invalid' do
      let(:task_params) { { title: '  ' } }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns the json error for title' do
        expect(json_body[:errors]).to have_key(:title)
      end

      it 'does not updates the task in the database' do
        expect(Task.find_by(title: task_params[:title])).to be_nil
      end
    end
  end

  describe 'DELETE /task/:id' do
    let!(:task) { create(:task, user_id: user.id) }

    before do
      delete "/tasks/#{task.id}", params: {}, headers: headers
    end

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end

    it 'removes the task from the database' do
      expect { Task.find(task.id) }.to raise_error(ActiveRecord::RecordNotFound)
      # expect( Task.find_by(id: task.id) ).to be_nil
    end
  end
end
