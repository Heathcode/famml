#! /usr/local/bin/lua



-----------------------------------------------------------------------------
-- Copyright (c) 2013, Benjamin Heath (benjamin.joel.heath@gmail.com)
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
--
--    Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
--    Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
--
--THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH  DAMAGE.
-----------------------------------------------------------------------------




-----------------------------------------------------------------------------
-- Famml
-- A program to convert MML to 6502 assembly that is compatible with Shiru's FamiTone and ca65.
-- FamiTone is a public domain audio driver for NES development.
-- 
-- For more information on MML, see http://en.wikipedia.org/wiki/Music_Macro_Language
--   Also see http://www.nullsleep.com/treasure/mck_guide/
-- For more information on 6502 assembly, see http://www.atariarchives.org/mlb/
-- For more information on FamiTone, see its announcement in the nesdev forums at http://forums.nesdev.com/viewtopic.php?t=7329
--   Also see Shiru's tutorial and Chase game, http://shiru.untergrund.net/articles/programming_nes_games_in_c.htm
-- For more information on ca65, see http://www.cc65.org
-----------------------------------------------------------------------------



-----------------------------------------------------------------------------
-- For reference, the following is copied from FamiTone's "formats.txt" by Shiru
-- 
-- Envelope format:
-- 
-- <127 is a number of repeats of previous output value
-- 127 is end of an envelope, next byte is new offset in envelope
-- 128..255 is output value + 192 (it is in -64..63 range)
-- 
-- Envelopes can't be longer than 255 bytes
-- 
-- 
-- Stream format:
-- 
-- %00nnnnnn is a note (0..59 are octaves 1-5, 63 note stop)
-- %01iiiiii is an instrument number (0 is default, silence)
-- %10rrrrrr is a empty rows (up to 63)
-- %11eeeeee is a special tag or effect
--    eeeeee $01..19 speed
-- %11111110 is end of the stream, two next bytes are new pointer
-- %11111111 is a reference (next two bytes of absolute address, and number of rows)
-- 
-- No octaves on Noise channel, it is always 0..15; no instruments and octaves on DPCM channel, it is always one octave
-- 
-- 
-- Sound effect format:
-- 
-- <16 is a remapped register number followed by a byte of data
-- >=16 is a number of frames to skip before reading next block of data - 16 (16 if next frame is not empty)
-- 255 is end of the effect
-- 
-- Sound effect data can't be longer than 255 bytes
-- 
-- Registers are remapped:
-- 
-- $4000 00
-- $4002 01
-- $4003 02
-- $4004 03
-- $4006 04
-- $4007 05
-- $4008 06
-- $400a 07
-- $400b 08
-- $400c 09
-- $400e 0a
-- 
-- 
-- RAM usage:
-- 
-- $00 frame counter, used to count time between rows
-- $01 current song speed
-- $02 instruments offset LSB
-- $03 instruments offset MSB
-- $04 previous MSB of Pulse 1
-- $05 previous MSB of Pulse 2
-- 
-- $06 channel 1 repeat counter (counts empty rows)
-- $07 channel 1 current note
-- $08 channel 1 current instrument
-- $09 channel 1 current duty
-- $0a channel 1 pointer LSB
-- $0b channel 1 pointer MSB
-- $0c channel 1 return LSB
-- $0d channel 1 return MSB
-- $0e channel 1 reference length counter (counts rows before return)
-- 
-- $0f channel 2 repeat counter
-- $10 channel 2 current note
-- $11 channel 2 current instrument
-- $12 channel 2 current duty
-- $13 channel 2 pointer LSB
-- $14 channel 2 pointer MSB
-- $15 channel 2 return LSB
-- $16 channel 2 return MSB
-- $17 channel 2 reference length counter
-- 
-- $18 channel 3 repeat counter
-- $19 channel 3 current note
-- $1a channel 3 current instrument
-- $1b channel 3 current duty
-- $1c channel 3 pointer LSB
-- $1d channel 3 pointer MSB
-- $1e channel 3 return LSB
-- $1f channel 3 return MSB
-- $20 channel 3 reference length counter
-- 
-- $21 channel 4 repeat counter
-- $22 channel 4 current note
-- $23 channel 4 current instrument
-- $24 channel 4 current duty
-- $25 channel 4 pointer LSB
-- $26 channel 4 pointer MSB
-- $27 channel 4 return LSB
-- $28 channel 4 return MSB
-- $29 channel 4 reference length counter
-- 
-- $2a channel 5 repeat counter
-- $2b channel 5 current note
-- $2c channel 5 current instrument
-- $2d channel 5 current duty
-- $2e channel 5 pointer LSB
-- $2f channel 5 pointer MSB
-- $30 channel 5 return LSB
-- $31 channel 5 return MSB
-- $32 channel 5 reference length counter
-- 
-- $33 channel 1 volume envelope output
-- $34 channel 1 volume envelope repeat counter
-- $35 channel 1 volume envelope address LSB
-- $36 channel 1 volume envelope address MSB
-- $37 channel 1 volume envelope pointer
-- $38 channel 1 arpeggio envelope output
-- $39 channel 1 arpeggio envelope repeat counter
-- $3a channel 1 arpeggio envelope address LSB
-- $3b channel 1 arpeggio envelope address MSB
-- $3c channel 1 arpeggio envelope pointer
-- $3d channel 1 pitch envelope output
-- $3e channel 1 pitch envelope repeat counter
-- $3f channel 1 pitch envelope address LSB
-- $40 channel 1 pitch envelope address MSB
-- $41 channel 1 pitch envelope pointer
-- 
-- $42 channel 2 volume envelope output
-- $43 channel 2 volume envelope repeat counter
-- $44 channel 2 volume envelope address LSB
-- $45 channel 2 volume envelope address MSB
-- $46 channel 2 volume envelope pointer
-- $47 channel 2 arpeggio envelope output
-- $48 channel 2 arpeggio envelope repeat counter
-- $49 channel 2 arpeggio envelope address LSB
-- $4a channel 2 arpeggio envelope address MSB
-- $4b channel 2 arpeggio envelope pointer
-- $4c channel 2 pitch envelope output
-- $4d channel 2 pitch envelope repeat counter
-- $4e channel 2 pitch envelope address LSB
-- $4f channel 2 pitch envelope address MSB
-- $50 channel 2 pitch envelope pointer
-- 
-- $51 channel 3 volume envelope output
-- $52 channel 3 volume envelope repeat counter
-- $53 channel 3 volume envelope address LSB
-- $54 channel 3 volume envelope address MSB
-- $55 channel 3 volume envelope pointer
-- $56 channel 3 arpeggio envelope output
-- $57 channel 3 arpeggio envelope repeat counter
-- $58 channel 3 arpeggio envelope address LSB
-- $59 channel 3 arpeggio envelope address MSB
-- $5a channel 3 arpeggio envelope pointer
-- $5b channel 3 pitch envelope output
-- $5c channel 3 pitch envelope repeat counter
-- $5d channel 3 pitch envelope address LSB
-- $5e channel 3 pitch envelope address MSB
-- $5f channel 3 pitch envelope pointer
-- 
-- $60 channel 4 volume envelope output
-- $61 channel 4 volume envelope repeat counter
-- $62 channel 4 volume envelope address LSB
-- $63 channel 4 volume envelope address MSB
-- $64 channel 4 volume envelope pointer
-- $65 channel 4 arpeggio envelope output
-- $66 channel 4 arpeggio envelope repeat counter
-- $67 channel 4 arpeggio envelope address LSB
-- $68 channel 4 arpeggio envelope address MSB
-- $69 channel 4 arpeggio envelope pointer
-- 
-- $6a DPCM table pointer LSB
-- $6b DPCM table pointer LSB
-- $6c DPCM sound effect active
-- $6d Sound effects data LSB
-- $6e Sound effects data MSB
-- $6f PAL adjust counter
-- 
-- $70 Main output buffer (11 bytes)
-- 
-- $7c Sound effect stream 1 repeat counter
-- $7d Sound effect stream 1 pointer LSB
-- $7e Sound effect stream 1 pointer MSB
-- $7f Sound effect stream 1 offset
-- $80 Sound effect stream 1 output buffer (11 bytes)
-- 
-- $8b Sound effect stream 2 repeat counter
-- $8c Sound effect stream 2 pointer LSB
-- $8d Sound effect stream 2 pointer MSB
-- $8e Sound effect stream 2 offset
-- $8f Sound effect stream 2 output buffer (11 bytes)
-- 
-- $9a Sound effect stream 3 repeat counter
-- $9b Sound effect stream 3 pointer LSB
-- $9c Sound effect stream 3 pointer MSB
-- $9d Sound effect stream 3 offset
-- $9e Sound effect stream 3 output buffer (11 bytes)
-- 
-- $a9 Sound effect stream 4 repeat counter
-- $aa Sound effect stream 4 pointer LSB
-- $ab Sound effect stream 4 pointer MSB
-- $ac Sound effect stream 4 offset
-- $ad Sound effect stream 4 output buffer (11 bytes)
-----------------------------------------------------------------------------



-----------------------------------------------------------------------------
-- For reference, the following is copied from the level music for Shiru's sample NES game, Chase.
-- mus_level_module:
-- 	.word @chn0,@chn1,@chn2,@chn3,@chn4,music_instruments
-- 	.byte $03
-- 
-- @chn0:
-- @chn0_0:
-- 	.byte $47,$18,$80,$18,$80,$1a,$8a
-- @chn0_loop:
-- @chn0_1:
-- 	.byte $8f
-- 	.byte $fe
-- 	.word @chn0_loop
-- 
-- @chn1:
-- @chn1_0:
-- 	.byte $48,$18,$80,$18,$80,$1a,$8a
-- @chn1_loop:
-- @chn1_1:
-- 	.byte $8f
-- 	.byte $fe
-- 	.word @chn1_loop
-- 
-- @chn2:
-- @chn2_0:
-- 	.byte $41,$18,$80,$18,$80,$49,$18,$41,$1a,$81,$3f,$86
-- @chn2_loop:
-- @chn2_1:
-- 	.byte $8f
-- 	.byte $fe
-- 	.word @chn2_loop
-- 
-- @chn3:
-- @chn3_0:
-- 	.byte $46,$0f,$80,$0f,$80,$49,$0b,$80,$42,$0f,$88
-- @chn3_loop:
-- @chn3_1:
-- 	.byte $8f
-- 	.byte $fe
-- 	.word @chn3_loop
-- 
-- @chn4:
-- @chn4_0:
-- 	.byte $8f
-- @chn4_loop:
-- @chn4_1:
-- 	.byte $8f
-- 	.byte $fe
-- 	.word @chn4_loop
-----------------------------------------------------------------------------



-----------------------------------------------------------------------------
-- And finally, a sample sound effect from Shiru's game, Chase.
-- sfx0:
-- 	.byte $00,$7f
-- 	.byte $01,$ab
-- 	.byte $02,$01
-- 	.byte $13
-- 	.byte $01,$3f
-- 	.byte $13
-- 	.byte $01,$1c
-- 	.byte $13
-- 	.byte $01,$d5
-- 	.byte $02,$00
-- 	.byte $13
-- 	.byte $01,$9f
-- 	.byte $13
-- 	.byte $01,$8e
-- 	.byte $13
-- 	.byte $00,$74
-- 	.byte $01,$ab
-- 	.byte $02,$01
-- 	.byte $13
-- 	.byte $01,$3f
-- 	.byte $13
-- 	.byte $01,$1c
-- 	.byte $13
-- 	.byte $01,$d5
-- 	.byte $02,$00
-- 	.byte $13
-- 	.byte $01,$9f
-- 	.byte $13
-- 	.byte $01,$8e
-- 	.byte $13
-- 	.byte $00,$71
-- 	.byte $01,$ab
-- 	.byte $02,$01
-- 	.byte $13
-- 	.byte $01,$3f
-- 	.byte $13
-- 	.byte $01,$1c
-- 	.byte $13
-- 	.byte $01,$d5
-- 	.byte $02,$00
-- 	.byte $13
-- 	.byte $01,$9f
-- 	.byte $13
-- 	.byte $01,$8e
-- 	.byte $13
-- 	.byte $00,$30
-- 	.byte $ff
-----------------------------------------------------------------------------



-----------------------------------------------------------------------------
-- The idea for this program, famml, is to take mml from either stdin or a text file,
-- and translate it to 6502 assembly which is compatible with FamiTone as well as the assembler, ca65.
-- However, it need not be specific to ca65. Allowance can easily be made for other assemblers.
-----------------------------------------------------------------------------



-----------------------------------------------------------------------------
-- Assembler settings table
-- An assembler settings table has the strings to output for a specific assembler
-----------------------------------------------------------------------------
local asm_template = {
	byte="\t.byte ",
	word="\t.word ",
	label=function(name) return name..":" end,
	clabel=function(name) return "@"..name..":" end,
	hexval=function(num) return "$"..tostring(tonumber(num,16)) end,
}



local asm_ca65 = template_asm



-----------------------------------------------------------------------------
-- translate(context input, output, asm, audiotype)
-- translate() takes an MML context table, a string as input, a file as output,
-- an assembler settings table, and a string which is either "sound" or "music".
-- translate() then writes to output, and returns its MML context and any error as a string.
-----------------------------------------------------------------------------
local function translate(context, input, output, asm, audiotype)
	-----------------------------------------------------------------------------
	-- doline(line, context)
	-- Parse a line
	-----------------------------------------------------------------------------
	local function doline(line, context)
		-----------------------------------------------------------------------------
		-- Capture the title
		-----------------------------------------------------------------------------
		do
			for title in string.gmatch(line, "#TITLE%s(.)") do
				if context.title == nil then
					context.title = title
				else
					return context, "One title only, please."
				end
			end
		end

		-----------------------------------------------------------------------------
		-- Capture the composer
		-----------------------------------------------------------------------------
		do
			for composer in string.gmatch(line, "#COMPOSER%s(.)") do
				if context.composer == nil then
					context.composer = composer
				else
					return context, "To credit more than one composer, please put them all on one line."
				end
			end
		end

		-----------------------------------------------------------------------------
		-- Capture envelopes
		-----------------------------------------------------------------------------
		do
			local function getenvelarray(envstring)
				n = {}
				for i in string.gmatch(envstring, "(%d+)") do
					table.insert(n, i)
				end
			end

			for k,v in string.gmatch(line, "@(v%d)%s=%s(%b{})") do
				if v then
					if context.envelopes == nil then
						context.envelopes = {}
						context.envelopes[k] = getenvelarray(v)
					elseif context.envelopes[k] == nil then
						context.envelopes[k] = getenvelarray(v)
					else
						return context, "Envelopes must be constant."
					end
				end
			end
		end

		return context
	end

	-----------------------------------------------------------------------------
	-- Cycle through all the lines
	-----------------------------------------------------------------------------
	do
		for line in string.gmatch(input, "(.+)\n") do
			context, err = doline(line, context)
			if err then return context, err end
		end
	end

	return context
end



-----------------------------------------------------------------------------
-- help()
-- Just show some friendly information about the program. :)
-----------------------------------------------------------------------------
local function help()
	print("Famml! - Convert MML to assembly compatible with NES and FamiTone\n")
	print("   -h  See this help screen")
	print("   -o  Redirect output to a file, as opposed to standard output")
	print("   -p  Accept input from a pipe")
	print()
	print("   -a  Load assembler settings from a file (default is ca65)")
	print("   -s  Output sfx")
	print("   -m  Output music (default)")
end


-----------------------------------------------------------------------------
-- cli(context)
-- cli() handles the command-line interface, with all the parameters to be used.
-----------------------------------------------------------------------------
local function cli(context)
	-----------------------------------------------------------------------------
	-- Default options
	-----------------------------------------------------------------------------
	local input = ""
	local output = io.stdout
	local asm = asm_ca65
	local audiotype = "music"

	-----------------------------------------------------------------------------
	-- checkparams(context)
	-- checkparams validates the parameters in arg
	-----------------------------------------------------------------------------
	function checkparams(context)
		local i = 0
		local pipemode = false
		local intermode = false
		local soundmode = false
		local musicmode = false
		repeat
			i = i + 1
			if arg[i] == "-p" then pipemode = true end
			if arg[i] == "-s" then soundmode = true end
			if arg[i] == "-m" then musicmode = true end
			if arg[i] == "-h" then help() return end
			if arg[i] == "-o" then
				if i == #arg then
					return context, "Output file expected after -o\n"
				elseif arg[1] == arg[i+1] then
					return context, "Cannot read from and write to the same file.\n"
				end
			end
			if arg[i] == "-a" then
				if i == #arg then
					return context, "Assembler settings file expected after -a\n"
				end
			end
		until i >= #arg
		if soundmode and musicmode then
			return context, "Because FamiTone's sfx and music formats differ, please select one or the other.\n"
		end

		return context
	end

	-----------------------------------------------------------------------------
	-- Process the parameters, including pipe and interactive mode
	-----------------------------------------------------------------------------
	function readinput(context)
		local i = 0
		repeat
			i = i + 1
			if arg[i] == "-p" then
				-- Pipe mode!
				input = io.read("*all")
			elseif arg[i] == "-o" then
				if arg[i+1] then
					output, err = io.open(arg[i+1], "a+")
					if output == nil then
						return context, "Could not open output file '"..arg[i+1].."'\n"
					end
				end
			elseif arg[i] == "-s" then
				audiotype = "sound"
			elseif arg[i] == "-m" then
				audiotype = "music"
			elseif arg[i] == "-a" then
				if arg[i+1] then
					asm = dofile(arg[i+1])
				end
			else
				-- All other options are checked. If this far, then arg[1] is input file.
				if i == 1 then
					local f = io.open(arg[1])
					if f == nil then
						return context, "Could not open input file '"..arg[1].."'. Expected input file as first argument.\n"
					end
					input = f:read("*all")
					f:close()
				end
			end
		until i >= #arg

		return context
	end

	-----------------------------------------------------------------------------
	-- Now to the meat of the function
	-----------------------------------------------------------------------------
	context,err = checkparams(context)
	if err then
		io.stderr:write(err.."\n")
		return
	end

	context,err = readinput(context)
	if err then
		io.stderr:write(err.."\n")
		return
	end

	context,err = translate(context, input, output, asm, audiotype)
	if not output == io.stdout then output:close() end
	if err then
		io.stderr:write(err.."\n")
		return
	end
end



-----------------------------------------------------------------------------
-- If this script is loaded from the interpreter or without parameters, it should just help().
-----------------------------------------------------------------------------
if arg == nil then
	help()
elseif #arg <= 0 then
	help()
else
	return cli({})
end
