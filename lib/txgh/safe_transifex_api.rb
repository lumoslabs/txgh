module Txgh
  class SafeTransifexApi < TransifexApi
    def create_or_update(*args)
      true
    end

    def create(*args)
      true
    end

    def delete(*args)
      true
    end

    def update_content(*args)
      true
    end

    def update_details(*args)
      true
    end
  end
end

