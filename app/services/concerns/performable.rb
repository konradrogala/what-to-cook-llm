module Performable
  extend ActiveSupport::Concern

  class_methods do
    def perform(*args, **kwargs)
      if kwargs.empty?
        new(*args).perform
      else
        new(*args, **kwargs).perform
      end
    end
  end
end
