class Mongodb < Formula
  desc "High-performance, schema-free, document-oriented database"
  homepage "https://www.mongodb.com/"

  # frozen_string_literal: true

  url "http://127.0.0.1/static/mongodb-macos-x86_64-4.2.5.tgz"
#   sha256 "f6436b5c981618fd54ccbc4c07ec64d3c64de680c61b4af99c3f55235fb4a3e0"

  bottle :unneeded

  keg_only :versioned_formula

  def install
    prefix.install Dir["*"]
  end

  def post_install
    %w[mongodb/run/ mongodb/log/ mongodb/data/].each { |p| (var/p).mkpath }
    if !(File.exist?((etc/"mongodb/mongod.conf"))) then
      (etc/"mongodb/mongod.conf").write mongodb_conf
    end
  end

  def mongodb_conf; <<~EOS
    processManagement:
      pidFilePath: #{var}/mongodb/run/mongod.pid
    systemLog:
      destination: file
      path: #{var}/mongodb/log/mongod.log
      logAppend: true
    storage:
      dbPath: #{var}/mongodb/data/
    net:
      bindIp: 127.0.0.1
  EOS
  end

  plist_options :manual => "mongod --config #{HOMEBREW_PREFIX}/etc/mongodb/mongod.conf"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_bin}/mongod</string>
        <string>--config</string>
        <string>#{etc}/mongodb/mongod.conf</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>KeepAlive</key>
      <false/>
      <key>WorkingDirectory</key>
      <string>#{HOMEBREW_PREFIX}</string>
      <key>StandardErrorPath</key>
      <string>#{var}/mongodb/log/output.log</string>
      <key>StandardOutPath</key>
      <string>#{var}/mongodb/log/output.log</string>
      <key>HardResourceLimits</key>
      <dict>
        <key>NumberOfFiles</key>
        <integer>64000</integer>
      </dict>
      <key>SoftResourceLimits</key>
      <dict>
        <key>NumberOfFiles</key>
        <integer>64000</integer>
      </dict>
    </dict>
    </plist>
  EOS
  end

  test do
    system "#{bin}/mongod", "--sysinfo"
  end
end
