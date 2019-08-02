require "rtmidi"
require "thread"
require 'fiddle/import'
require "socket"
require "json"

##############################################################################
# Fiddleでリンクライブラリ読み込み
module M
    extend Fiddle::Importer
    dlload 'libsudare.so'
    extern 'int sudare_init_sdk(const char* dst)'
    extern 'int sudare_set_led_rect(int x, int y, int z, int rgb)'
    extern 'int sudare_set_led_polar(int a, int r, int h, int rgb)'
    extern 'int sudare_clear(void)'
    extern 'int sudare_send(void)'
    extern 'int sudare_sleep(int ms)'
end

exit(1) unless M.sudare_init_sdk('localhost:5510').zero?

class MidiReciever
    def initialize(table)
        @table = table
        @midiin = RtMidi::In.new
        @port_index=1
    end

    def selectport
        puts "Available MIDI input ports"
        @midiin.port_names.each_with_index{|name,index| printf "%3i: %s\n", index, name }
        #[bug]port_indexが入力されるまで待ちたいけど待ってくれない、初期値で動作している
        @port_index = _selectport until @port_index
        puts "#@port_index"
    end

    def recieve
        @push_thread = Thread.start do
            @midiin.receive_channel_message do |byte1, byte2, byte3|
                #puts "#{byte1} #{byte2} #{byte3}"
                @table.push(byte2)
            end
            puts "Receiving MIDI channel messages..."
            @midiin.open_port(@port_index)
        end
    end

    private
        def _selectport
            puts "Available MIDI input ports"
            @midiin.port_names.each_with_index{|name,index| printf "%3i: %s\n", index, name }
            print "Select a port number: "
            if (port = gets) =~ /^\d+$/
                return port.to_i if (0...@midiio.port_count).include? port.to_i
            end
            puts "Invalid port number"
        end
end

class Table
    def initialize()
        @queues = Array.new
        @queue_max = 20
        @mutex = Mutex.new
        @cv = ConditionVariable.new
    end

    def push(num)
        @mutex.synchronize do
        while @queues.size() >= @queue_max
            @cv.wait(@mutex)
        end
        @queues.push(num)
        @cv.broadcast
        end
    end

    def take()
        @mutex.synchronize do
        while @queues.size() == 0
            @cv.wait(@mutex)
        end
        temp = @queues.first
        queue = @queues.shift()
        @cv.broadcast
        return temp
        end
    end
end

class LedSender
    def initialize(table)
        @table = table
        @udp = UDPSocket.open()
        @sockaddr = Socket.pack_sockaddr_in(10000, "127.0.0.1")
    end

    def send
        @take_thread = Thread.start do
            loop do
                num = @table.take()
                js = convert2json(num)
                puts js
                @udp.send(js, 0, @sockaddr)
                sleep 0.5
            end
        end
    end

    private
    def convert2color(num)
        case num
        #####白鍵####
        when 48 then
        when 50 then
        when 52 then
        when 53 then
        when 55 then
        when 57 then
        when 59 then
        when 60 then
        when 62 then
            return 0xff0000
        when 64 then
            return 0x0000ff
        when 65 then
        when 67 then
        when 69 then
        when 71 then
        when 72 then
        else
            return 0xffffff
        end
    end
    def convert2json(num)
        h = Hash.new
        case num
        #####白鍵####
        when 48 then
            return JSON.generate({ "image" => "btc"})
        when 50 then
            return JSON.generate({ "image" => "chopper"})
        when 52 then
            return JSON.generate({ "image" => "doraemon"})
        when 53 then
            return JSON.generate({ "image" => "dorami"})
        when 55 then
            return JSON.generate({ "image" => "droid"})
        when 57 then
            return JSON.generate({ "image" => "elsa"})
        when 59 then
            return JSON.generate({ "image" => "krillin"})
        when 60 then
            return JSON.generate({ "image" => "makey"})
        when 62 then
            return JSON.generate({ "image" => "miku"})
        when 64 then
            return JSON.generate({ "image" => "minion"})
        when 65 then
            return JSON.generate({ "image" => "pikachu"})
        when 67 then
            return JSON.generate({ "image" => "popteamepic"})
        when 69 then
            return JSON.generate({ "image" => "r2d2"})
        when 71 then
            return JSON.generate({ "image" => "rocket"})
        when 72 then
            return JSON.generate({ "image" => "slime"})
        ####黒鍵####
        when 49 then
            return JSON.generate({ "action" => "stop"})
        when 51 then
            return JSON.generate({ "action" => "stop"})
        when 54 then
            return JSON.generate({ "action" => "bottom_up"})
        when 56 then
            return JSON.generate({ "action" => "left_right"})
        when 58 then
            return JSON.generate({ "action" => "back_front"})
        when 61 then
            return JSON.generate({ "action" => "stop"})
        when 63 then
            return JSON.generate({ "action" => "stop"})
        when 66 then
            return JSON.generate({ "action" => "bottom_up"})
        when 68 then
            return JSON.generate({ "action" => "left_right"})
        when 70 then
            return JSON.generate({ "action" => "back_front"})
        else
            return JSON.generate({ "action" => "null"})
        end
    end
end

table = Table.new
midircv = MidiReciever.new(table)
ledsdr  = LedSender.new(table)

midircv.selectport
midircv.recieve
ledsdr.send


sleep # prevent Ruby from exiting immediately
