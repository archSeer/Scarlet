require 'scarlet/models/model_base'
require 'moon-repository/query'

class Scarlet
  class Nick < ModelBase
    extend RecordRepository

    field :nick,       type: String,  validate: { presence: {} }
    field :aliases,    type: Array,   default: proc { Array.new }
    # owner > dev > admin > mod > (every other user)
    field :groups,     type: Array,   default: proc { ['user'] }
    field :win_points, type: Integer, default: 0
    field :settings,   type: Hash,    default: proc { Hash.new }

    # Similar to updating the settings manually and then calling save on the nick
    #
    # @param [Hash] opts
    def update_settings(opts)
      settings.merge!(opts)
      save
    end

    # Checks if the nick is apart of the given groups
    #
    # @param [String] expected
    # @return [Boolean]
    def groups?(*expected)
      (groups & expected) == expected
    end
    alias :group? :groups?

    def root?
      group?('root')
    end

    def sudo?
      root? || group?('sudo')
    end

    def eval?
      root? || group?('eval')
    end

    def registered?
      root? || group?('user')
    end

    def self.owner
      first groups: Moon::Repository::Query.includes?('root')
    end
  end
end
