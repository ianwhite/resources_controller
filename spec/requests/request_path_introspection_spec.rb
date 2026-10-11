require 'spec_helper'

describe "Resource path scoping", :type => :request do
  before do
    @info = Info.create!
    @account = User.create!(:info => @info)
    @tag = @info.tags.create!
    other_info = Info.create!
    User.create!(:info => other_info)
    @other_tag = other_info.tags.create!
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@account)
  end

  it "should reject a query override that looks up another user's resource" do
    get "/account/info/tags/#{@other_tag.id}", :params => { :resource_path => '/tags' }

    expect(response).to have_http_status(:not_found)
  end

  it "should find the current user's resource despite a query override" do
    get "/account/info/tags/#{@tag.id}", :params => { :resource_path => '/tags' }

    expect(response).to have_http_status(:ok)
    expect(assigns[:tag]).to eq(@tag)
    expect(assigns[:account]).to eq(@account)
  end

  it "should reject a body override that deletes another user's resource" do
    delete "/account/info/tags/#{@other_tag.id}", :params => { :resource_path => '/tags' }

    expect(response).to have_http_status(:not_found)
    expect(Tag.exists?(@other_tag.id)).to be true
  end

  it "should delete the current user's resource despite a body override" do
    delete "/account/info/tags/#{@tag.id}", :params => { :resource_path => '/tags' }

    expect(response).to redirect_to('/account/info/tags')
    expect(Tag.exists?(@tag.id)).to be false
    expect(Tag.exists?(@other_tag.id)).to be true
  end
end
