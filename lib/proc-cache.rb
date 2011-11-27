require 'tmpdir'

class Proc
  def cache!(options={})
    cache_path = tmp_cache_path
    @logger = Logger.new(nil)

    cache_path = options[:cache_path] if options[:cache_path]
    expires = options[:expires] if options[:expires]
    @logger = options[:logger] if options[:logger]

    if File.exist? cache_path
      @logger.info "cache file found: #{cache_path}"
      return use_cache(cache_path, expires)
    else
      @logger.info "cache file not found, generating cache"
      data = self.call
      write_cache(cache_path, data)
      return data
    end
  end

  private
  def use_cache(cache_path, expires)
    @logger.info "use cache"
    @logger.info "expire is: #{expires.inspect}"
    if expires.nil?
      return read_cache(cache_path)
    end

    next_update = File::stat(cache_path).mtime + expires
    @logger.info "next update: #{next_update}"
    if next_update < Time.now
      @logger.info "need to update cache file, updating now"
      data = self.call
      write_cache(cache_path, data)
      return data
    else
      return read_cache(cache_path)
    end
  end

  def read_cache(cache_path)
    @logger.info "read cache: #{cache_path}"
    Marshal.restore( File.read(cache_path) )
  end

  def write_cache(cache_path, data)
    @logger.info "write cache: #{cache_path} length:#{data.size}"
    File.open(cache_path, "wb"){ |f|
      f.write Marshal.dump(data)
    }
    data
  end

  def tmp_cache_path
    File.join(Dir.tmpdir, "#{File.basename($0)}.cache")
  end
end

__END__
p Proc.new{ sleep 3; 1 }.cache!(:expires => 1.hours)

