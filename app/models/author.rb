class Author < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable,
         :validatable, :trackable

  has_many :documents, dependent: :nullify

  validates :email, presence: true, uniqueness: true

  def name
    email.split("@").first
  end
end
