# frozen_string_literal: true

require "guard/compat/plugin"
require "colorize"
require "json"

module Guard
  class StandardJs < Plugin
    attr_accessor :notify_on, :all_on_start

    def initialize(options = {})
      @notify_on    = options.fetch(:notify_on, :failure)
      @all_on_start = options.fetch(:all_on_start, true)
      super
    end

    def start
      run_all if all_on_start
    end

    def run_all
      ignored_paths = JSON.load_file("package.json")["standard"]["ignore"].map { |path| path.delete_prefix("/") }

      all_paths = (Dir.glob("app/**/*.js") + Dir.glob("test/dummy/app/**/*.js")).select do |path|
        ignored_paths.none? { |ignored_path| path.start_with?(ignored_path) }
      end

      run(all_paths)
    end

    def run_on_modifications(paths)
      run(paths)
    end

    def run_on_additions(paths)
      run(paths)
    end

    private
      def run(paths)
        return if paths.nil?

        result = system "npx standard --fix #{paths.join(' ')}"

        if result
          UI.info "No Standard JS offences detected".green
        else
          UI.info "Standard JS offences has been detected".red
        end

        check_and_notify(result)
      end

      def notification_allowed?(result)
        case notify_on
        when :failure then !result
        when :success then result
        when :both then true
        when :none then false
        end
      end

      def check_and_notify(result)
        notify(result) if notification_allowed?(result)
      end

      def image(result)
        result ? :success : :failed
      end

      def message(result)
        result ? "No Standard JS offences" : "Standard JS offences detected"
      end

      def notify(result)
        Notifier.notify(message(result), title: "Standard JS results", image: image(result))
      end
  end
end
