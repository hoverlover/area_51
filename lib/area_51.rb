module Area51
  autoload :AuthorizationTrigger, 'area_51/authorization_trigger'

  module ApiMethod

    # This is the entry point into the Area51 library.  Here are some usage examples:
    #
    #   class ApplicationController < ActionController::Base
    #     area_51 do
    #       authorization_trigger("current_user.active?", :unrestricted) do
    #         restricted_area "^/memers_only"
    #         unrestricted_area "^/$"
    #       end
    #
    #       authorization_trigger(true, :restricted) do
    #         restricted_area "/top/secret/path"
    #         unrestricted_area "/anyone_allowed"
    #       end
    #
    #       trigger = proc {
    #         # Some useful trigger condition here
    #       }
    #       authorization_trigger(trigger) do
    #         unrestricted_area %r{^/totally_open}
    #         unrestricted_area %r{^/anyone_allowed$}
    #       end
    #     end
    #   end
    #
    # See documentation for authorization_trigger for details on how to use this method.
    #
    def area_51(&block)
      self.send :extend, ClassMethods
      self.send :include, InstanceMethods

      self.default_access = :restricted
      self.before_filter :area_51_check_access

      yield
    end
  end

  module ClassMethods

    def self.extended(klass)
      klass.cattr_accessor :authorization_trigger_paths
      klass.cattr_accessor :authorization_triggers
      klass.cattr_accessor :safe_zone
      klass.cattr_accessor :default_access
    end

    # Defines a trigger condition that when met, will cause authorization
    # to be performed.
    #
    # The +trigger+ can be either a String, +lambda+, or Proc.
    # If a String, it will be +eval+'d, if a +lambda+ or Proc, it will
    # be called, and anything else will be returned as-is.  If the result
    # does not return an explicit +true+, authorization will not be performed.
    #
    # The +default_access+ parameter, if provided, must be one of +:restricted+ or
    # +:unrestricted+.  The default is +:restricted+.  This specifies what type
    # of access the undefined areas will have.  For example:
    #
    #   area_51 do
    #     authorization_trigger("current_user.active?", :unrestricted) do
    #       restricted_area "^/memers_only"
    #       unrestricted_area "^/$"
    #     end
    #   end
    #
    # Now if a user tries to access a path that isn't defined above, they will be granted access
    # due to the +:unrestricted+ parameter.
    #
    def authorization_trigger(trigger, default_access = nil, &block)
      trigger = AuthorizationTrigger.new(trigger, default_access)

      yield

      self.authorization_triggers ||= {}
      self.authorization_triggers[trigger] = self.authorization_trigger_paths.dup
      self.authorization_trigger_paths.clear
    end

    # Ties a restricted path to the authorization trigger.  Must be
    # called within an authorization_trigger block:
    #
    #  authorization_trigger("current_user.signed_in?") do
    #    restricted_area %r{/top/secret/path/}
    #  end
    #
    # +path+ can be either a String or a Regexp.  If a String, it will
    # be converted to a Regexp.
    #
    def restricted_area(path)
      add_path_to_trigger_paths path, :restricted
    end

    # Ties an unrestricted path to the authorization trigger.  Must be
    # called within an authorization_trigger block:
    #
    #  authorization_trigger("current_user.signed_in?") do
    #    unrestricted_area %r{/top/secret/path/}
    #  end
    #
    # +path+ can be either a String or a Regexp.  If a String, it will
    # be converted to a Regexp.
    #
    def unrestricted_area(path)
      add_path_to_trigger_paths path, :unrestricted
    end

  private

    def add_path_to_trigger_paths(path, type)
      path = Regexp.new(path) if path.is_a? String

      self.authorization_trigger_paths ||= {}
      (self.authorization_trigger_paths[type] ||= []) << path
    end
  end

  # This module contains methods which will be added as instance methods
  # to your controller.
  #
  module InstanceMethods

    # A +before_filter+ that checks if authorization is needed to access
    # the current path.  If authorization is needed, and it fails, the user
    # is redirected to the safe_zone, or to root_path if safe_zone is not defined.
    # It also sets +flash#notice+ with a message, which should be defined
    # in a locale file with the key +:restricted+.
    #
    def area_51_check_access
      if entering_unauthorized_area?(request.path)
        flash.notice = I18n.t(:restricted)
        redirect_to self.class.safe_zone || self.root_path
      end
    end

    # Checks to see if the user is entering a restricted zone.  It does this
    # by enumerating through the list of configured authorization triggers
    # for this controller.  If one of them returns +true+, the paths tied
    # to the trigger are checked against the current path.
    #
    # If the current path matches one of the paths configured for the trigger, and the access type
    # for the trigger is +:restricted+, the method returns +true+.  If it is
    # +:unrestricted+, or the current path is the same as the safe_zone, it returns +false.
    #
    def entering_unauthorized_area?(path)
      return false if path == self.class.safe_zone

      self.class.authorization_triggers.any? do |trigger, paths|
        if authorization_triggered? trigger

          # Now that we know an authorization should be performed, let's do it!

          if path.match(combined_paths(paths[:restricted]))
            true
          elsif path.match(combined_paths(paths[:unrestricted]))
            false
          else
            trigger.default_access == :restricted
          end
        end
      end
    end

  private

    def combined_paths(paths)
      paths ||= []
      Regexp.union(*(paths.compact))
    end

    def authorization_triggered?(trigger)
      trigger = trigger.body

      case
      when trigger.is_a?(String)
        result = eval trigger
      when trigger.respond_to?(:call)
        result = trigger.call
      else
        result = trigger
      end

      !!result
    end
  end
end

ActionController::Base.send :extend, Area51::ApiMethod
