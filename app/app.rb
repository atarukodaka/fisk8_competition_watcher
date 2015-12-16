module CompetitionWatcher
  class App < Padrino::Application
    use ConnectionPoolManagement
    register Padrino::Mailer
    register Padrino::Helpers

    enable :reload
    enable :sessions


    get '/' do
      "foo bar"
    end
  end
end
