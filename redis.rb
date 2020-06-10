class Redis < Formula
  desc "Persistent key-value database, with built-in net interface"
  homepage "https://redis.io/"
  url "http://127.0.0.1/static/redis-5.0.8.tar.gz"
#   sha256 "f3c7eac42f433326a8d981b50dba0169fdfaf46abb23fcda2f933a7552ee4ed7"
#   head "https://github.com/antirez/redis.git", :branch => "5.0"

#   bottle do
#     cellar :any_skip_relocation
#     sha256 "7a50c626ad90c40fd315f7f053460f0c6701cc2b776a1b3e83dc44698936cd0f" => :catalina
#     sha256 "e8956553dbc1f519bcd0330bd2d41eb884997303b84dd43be686a9d974e2d003" => :mojave
#     sha256 "789cf8094a5909d295ce3b9996b8470d565e6c9dedbc952176af670a660a8c6f" => :high_sierra
#   end

  def install
    # Architecture isn't detected correctly on 32bit Snow Leopard without help
    ENV["OBJARCH"] = "-arch #{MacOS.preferred_arch}"

    system "make", "install", "PREFIX=#{prefix}", "CC=#{ENV.cc}"

    %w[redis/run/ redis/data/ redis/log/].each { |p| (var/p).mkpath }
    (etc/"redis/").mkpath

    # Fix up default conf file to match our paths
    inreplace "redis.conf" do |s|
      s.gsub! "/var/run/redis_6379.pid", "#{var}/redis/run/redis.pid"
      s.gsub! "dir ./", "dir #{var}/redis/data/"
      s.sub!  /^bind .*$/, "bind 127.0.0.1 ::1"
    end

    (etc/"redis/").install "redis.conf"
    (etc/"redis/").install "sentinel.conf" => "redis-sentinel.conf"
  end

  plist_options :manual => "redis-server #{HOMEBREW_PREFIX}/etc/redis/redis.conf"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>KeepAlive</key>
        <dict>
          <key>SuccessfulExit</key>
          <false/>
        </dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/redis-server</string>
          <string>#{etc}/redis/redis.conf</string>
          <string>--daemonize no</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>WorkingDirectory</key>
        <string>#{var}/redis/</string>
        <key>StandardErrorPath</key>
        <string>#{var}/redis/log/redis.log</string>
        <key>StandardOutPath</key>
        <string>#{var}/redis/log/redis.log</string>
      </dict>
    </plist>
  EOS
  end

  test do
    system bin/"redis-server", "--test-memory", "2"
    %w[run db/redis log].each { |p| assert_predicate var/p, :exist?, "#{var/p} doesn't exist!" }
  end
end
