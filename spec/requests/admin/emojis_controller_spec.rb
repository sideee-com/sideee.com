# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::EmojisController do
  fab!(:admin) { Fabricate(:admin) }
  fab!(:upload) { Fabricate(:upload) }

  before do
    sign_in(admin)
  end

  describe '#index' do
    it "returns a list of custom emojis" do
      CustomEmoji.create!(name: 'osama-test-emoji', upload: upload)
      Emoji.clear_cache

      get "/admin/customize/emojis.json"
      expect(response.status).to eq(200)

      json = response.parsed_body
      expect(json[0]["name"]).to eq("osama-test-emoji")
      expect(json[0]["url"]).to eq(upload.url)
    end
  end

  describe "#create" do
    describe 'when upload is invalid' do
      it 'should publish the right error' do

        post "/admin/customize/emojis.json", params: {
          name: 'test',
          file: fixture_file_upload("#{Rails.root}/spec/fixtures/images/fake.jpg")
        }

        expect(response.status).to eq(422)
        parsed = response.parsed_body
        expect(parsed["errors"]).to eq([I18n.t('upload.images.size_not_found')])
      end
    end

    describe 'when emoji name already exists' do
      it 'should publish the right error' do
        CustomEmoji.create!(name: 'test', upload: upload)

        post "/admin/customize/emojis.json", params: {
          name: 'test',
          file: fixture_file_upload("#{Rails.root}/spec/fixtures/images/logo.png")
        }

        expect(response.status).to eq(422)
        parsed = response.parsed_body
        expect(parsed["errors"]).to eq([
          "Name #{I18n.t('activerecord.errors.models.custom_emoji.attributes.name.taken')}"
        ])
      end
    end

    it 'should allow an admin to add a custom emoji' do
      Emoji.expects(:clear_cache)

      post "/admin/customize/emojis.json", params: {
        name: 'test',
        file: fixture_file_upload("#{Rails.root}/spec/fixtures/images/logo.png")
      }

      custom_emoji = CustomEmoji.last
      upload = custom_emoji.upload

      expect(upload.original_filename).to eq('logo.png')

      data = response.parsed_body
      expect(response.status).to eq(200)
      expect(data["errors"]).to eq(nil)
      expect(data["name"]).to eq(custom_emoji.name)
      expect(data["url"]).to eq(upload.url)
      expect(custom_emoji.group).to eq(nil)
    end

    it 'should allow an admin to add a custom emoji with a custom group' do
      Emoji.expects(:clear_cache)

      post "/admin/customize/emojis.json", params: {
        name: 'test',
        group: 'Foo',
        file: fixture_file_upload("#{Rails.root}/spec/fixtures/images/logo.png")
      }

      custom_emoji = CustomEmoji.last

      data = response.parsed_body
      expect(response.status).to eq(200)
      expect(custom_emoji.group).to eq("foo")
    end

    it 'should fix up the emoji name' do
      Emoji.expects(:clear_cache).times(3)

      post "/admin/customize/emojis.json", params: {
        name: 'test.png',
        file: fixture_file_upload("#{Rails.root}/spec/fixtures/images/logo.png")
      }

      custom_emoji = CustomEmoji.last
      upload = custom_emoji.upload

      expect(upload.original_filename).to eq('logo.png')
      expect(custom_emoji.name).to eq("test")
      expect(response.status).to eq(200)

      post "/admin/customize/emojis.json", params: {
        name: 'st&#* onk$',
        file: fixture_file_upload("#{Rails.root}/spec/fixtures/images/logo.png")
      }

      custom_emoji = CustomEmoji.last
      expect(custom_emoji.name).to eq("st_onk_")
      expect(response.status).to eq(200)

      post "/admin/customize/emojis.json", params: {
        name: 'PaRTYpaRrot',
        file: fixture_file_upload("#{Rails.root}/spec/fixtures/images/logo.png")
      }

      custom_emoji = CustomEmoji.last
      expect(custom_emoji.name).to eq("partyparrot")
      expect(response.status).to eq(200)
    end
  end

  describe '#destroy' do
    it 'should allow an admin to delete a custom emoji' do
      custom_emoji = CustomEmoji.create!(name: 'test', upload: upload)
      Emoji.clear_cache

      expect do
        delete "/admin/customize/emojis/#{custom_emoji.name}.json",
          params: { name: 'test' }
      end.to change { CustomEmoji.count }.by(-1)
    end
  end
end
