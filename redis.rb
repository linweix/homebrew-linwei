class Redis < Formula
  desc "Persistent key-value database, with built-in net interface"
  homepage "https://redis.io/"
  url "https://mirrors.huaweicloud.com/redis/redis-5.0.10.tar.gz"
  sha256 "e30a5e7d1593a715cdda2a82deb90190816d06c9d1dc1ef5b36874878c683382"
  license "BSD-3-Clause"
  head "https://github.com/redis/redis.git", branch: "unstable"

  livecheck do
    url "https://download.redis.io/releases/"
    regex(/href=.*?redis[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any, arm64_big_sur: "0ae80e0e8a0a13d663a1d9e1c74bb17df56deb4b2edd5397b363ec4f6a32e43c"
    sha256 cellar: :any, big_sur:       "ecd20074b450f501345d7533abc51e8f47f28f27a5c8b7c698fe4d80aeb8126c"
    sha256 cellar: :any, catalina:      "92bc496f208cdbcbf5b9251d0e32bca775d19e800b5d19948c54c3f8d03f0c9b"
    sha256 cellar: :any, mojave:        "2c577a2692701929cc90f0bd2fd050e47705d8693086e1050b4b69ec95315ed1"
  end

  depends_on "openssl@1.1"

  def install
    system "make", "install", "PREFIX=#{prefix}", "CC=#{ENV.cc}", "BUILD_TLS=yes"

    %w[run data/redis log].each { |p| (var/p).mkpath }

    # Fix up default conf file to match our paths
    inreplace "redis.conf" do |s|
      s.gsub! "/var/run/redis.pid", var/"run/redis.pid"
      s.gsub! "dir ./", "dir #{var}/data/redis/"
      s.sub!(/^bind .*$/, "bind 127.0.0.1 ::1")
    end

    etc.install "redis.conf"
    etc.install "sentinel.conf" => "redis-sentinel.conf"
  end

  plist_options manual: "redis-server #{HOMEBREW_PREFIX}/etc/redis.conf"

  def plist
    <<~EOS
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
            <string>#{etc}/redis.conf</string>
            <string>--daemonize no</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
          <key>WorkingDirectory</key>
          <string>#{var}</string>
          <key>StandardErrorPath</key>
          <string>#{var}/log/redis.log</string>
          <key>StandardOutPath</key>
          <string>#{var}/log/redis.log</string>
        </dict>
      </plist>
    EOS
  end

  test do
    system bin/"redis-server", "--test-memory", "2"
    %w[run data/redis log].each { |p| assert_predicate var/p, :exist?, "#{var/p} doesn't exist!" }
  end
end
