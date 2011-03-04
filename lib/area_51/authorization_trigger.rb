module Area51
  class AuthorizationTrigger
    attr_accessor :default_access
    attr_accessor :body

    def initialize(body, default_access = nil)
      @body = body

      if [:restricted, :unrestricted].include?(default_access)
        @default_access = default_access
      else
        @default_access = :restricted
      end
    end
  end
end
