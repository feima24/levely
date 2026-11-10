class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :categories, dependent: :destroy
  has_many :daily_logs, dependent: :destroy
  has_many :monthly_goals, dependent: :destroy

  validates :password, format: {
    with: /\A(?=.*[a-zA-Z])(?=.*\d).{10,}\z/,
    message: 'は10文字以上の英数字を含む必要があります',
    allow_blank: true
  }
end
