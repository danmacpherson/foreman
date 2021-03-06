module Api
  module V2
    class UsersController < V2::BaseController
      include Foreman::Controller::UsersMixin
      include Api::Version2
      include Api::TaxonomyScope
      before_filter :find_resource, :only => %w{show update destroy}

      api :GET, "/users/", "List all users."
      param :search, String, :desc => "filter results"
      param :order, String, :desc => "sort results"
      param :page, String, :desc => "paginate results"
      param :per_page, String, :desc => "number of entries per request"

      def index
        @users = User.search_for(*search_options).paginate(paginate_options)
      end

      api :GET, "/users/:id/", "Show an user."
      param :id, String, :required => true

      def show
        @user
      end

      api :POST, "/users/", "Create an user."
      # TRANSLATORS: API documentation - do not translate
      description <<-DOC
        Adds role 'Anonymous' to the user by default
      DOC
      param :user, Hash, :required => true do
        param :login, String, :required => true
        param :firstname, String, :required => false
        param :lastname, String, :required => false
        param :mail, String, :required => true
        param :admin, :bool, :required => false, :desc => "Is an admin account?"
        param :password, String, :required => true
        param :auth_source_id, Integer, :required => true
      end

      def create
        if @user.save
          process_success
        else
          process_resource_error
        end
      end

      api :PUT, "/users/:id/", "Update an user."
      # TRANSLATORS: API documentation - do not translate
      description <<-DOC
        Adds role 'Anonymous' to the user if it is not already present.
        Only admin can set admin account.
      DOC
      param :id, String, :required => true
      param :user, Hash, :required => true do
        param :login, String
        param :firstname, String, :allow_nil => true
        param :lastname, String, :allow_nil => true
        param :mail, String
        param :admin, :bool, :desc => "Is an admin account?"
        param :password, String
      end

      def update
        if @user.update_attributes(params[:user])
          update_sub_hostgroups_owners

          process_success
        else
          process_resource_error
        end
      end

      api :DELETE, "/users/:id/", "Delete an user."
      param :id, String, :required => true

      def destroy
        if @user == User.current
          deny_access "You are trying to delete your own account"
        else
          process_response @user.destroy
        end
      end

      protected
      def resource_identifying_attributes
        %w(id login)
      end

    end
  end
end
