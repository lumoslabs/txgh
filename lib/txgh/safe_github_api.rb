module Txgh
  class SafeGithubApi < GithubApi
    def create_ref(*args)
      true
    end

    def commit(*args)
      true
    end
  end
end
