class Author::BaseController < ApplicationController
  before_action :authenticate_author!
  layout "author"
end
