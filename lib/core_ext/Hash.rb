class Hash
  def replace_key *args,&block
    dup.replace_key! *args, &block
  end

  def replace_key! hash={}
    k,v = [nil]*2
    if block_given?
      keyz = self.keys
      keyz.each do |k| v = yield k ; self[v] = self.delete k end
    else
      hash.each_pair do |k,v| self[v] = self.delete k end
    end
    self
  end

  def remap &block
    Hash[*self.map(&block).flatten]
  end

  def remap! &block
    self.replace remap(&block)
  end

  # instead of hash[:key][:key], hash.key.key
  def method_missing(method, *args)
    method_name = method.to_s
    unless respond_to? method_name
      if method_name.ends_with? '?'
        # if it ends with ? it's an existance check
        method_name.slice!(-1)
        key = keys.detect {|k| k.to_s == method_name }
        return !!self[key]
      elsif method_name.ends_with? '='
        # if it ends with = it's a setter, so set the value
        method_name.slice!(-1)
        key = keys.detect {|k| k.to_s == method_name }
        return self[key] = args.first
      end
    end
    # if it contains that key, return the value
    key = keys.detect {|k| k.to_s == method_name }
    return self[key] if key
    super
  end
end