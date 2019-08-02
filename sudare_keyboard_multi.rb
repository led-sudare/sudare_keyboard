require "rtmidi"
require "thread"
require 'fiddle/import'

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
                puts "#{byte1} #{byte2} #{byte3}"
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
    end

    def send
        @take_thread = Thread.start do
            loop do
                num = @table.take()
                puts num
                sleep 0.5
            end
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
