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
-- 	; $47 = instrument #7
-- 	; $18 = B, second octave
-- 	; $80 = empty row
-- 	; $1a = C#, third octave
-- 	; $8a = 10 empty rows
-- 	.byte $47,$18,$80,$18,$80,$1a,$8a
-- @chn0_loop:
-- @chn0_1:
-- 	; $8f = 15 empty rows
-- 	.byte $8f
-- 	; $fe = end
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
-- config_ca65_famitone()
-- Returns an interface for output to ca65 and FamiTone
-----------------------------------------------------------------------------
local function config_ca65_famitone()
	local asm_comment="; "
	local asm_byte="\t.byte "
	local asm_word="\t.word "
	local asm_label=function(name) return name..":" end
	local asm_clabel=function(name) return "@"..name..":" end

	-----------------------------------------------------------------------------
	-- asm_assembly()
	-- Returns an interface for adding to and writing the assembly output
	-----------------------------------------------------------------------------
	local function asm_assembly()
		local asm = {
			__code = {},
			__code_size = 0,

			-----------------------------------------------------------------------------
			-- asm:add_cheap_label(name)
			-----------------------------------------------------------------------------
			add_cheap_label = function(asm, name)
				local clabel = asm.__code[#asm.__code].clabel
				if string.len(clabel) > 0 then
					clabel = asm_clabel(name)
				else
					clabel = asm_clabel(name).."\n"..clabel
				end
				asm.__code[#asm.__code].clabel = clabel
			end,

			-----------------------------------------------------------------------------
			-- asm:add_comment(comment)
			-----------------------------------------------------------------------------
			add_comment = function(asm, comment)
				asm.__code[#asm.__code].comment = asm_comment..comment
			end,

			-----------------------------------------------------------------------------
			-- asm:add_label(name)
			-----------------------------------------------------------------------------
			add_label = function(asm, name)
				local label = asm.__code[#asm.__code].label
				if string.len(label) > 0 then
					label = asm_label(name).."\n"..label
				else
					label = asm_label(name)
				end
				asm.__code[#asm.__code].label = label
			end,

			-----------------------------------------------------------------------------
			-- asm:add_line()
			-----------------------------------------------------------------------------
			add_line = function(asm)
				row = {label="",clabel="",command="",args="",comment="",nargs=0,maxargs=10,}
				table.insert(asm.__code, row)
			end,

			-----------------------------------------------------------------------------
			-- asm:place_byte(n)
			-- Use the assembler's byte directive, such as .byte or db
			-----------------------------------------------------------------------------
			place_byte = function(asm, n)
				local line = asm.__code[#asm.__code]
				if line.command == "" then
					line.command = asm_byte
					if type(n) == "number" then
						line.args = line.args.."$"..string.format("%x",n)
					elseif type(n) == "string" then
						line.args = line.args.."$"..n
					end
					goto code_size
				elseif line.command == asm_byte then
					if type(n) == "number" then
						line.args = line.args..", $"..string.format("%x",n)
					elseif type(n) == "string" then
						line.args = line.args..", $"..n
					end
					goto code_size
				else
					asm:add_line()
					return asm:place_byte(n)
				end
				::code_size::
				asm.__code_size = asm.__code_size + 1
				line.nargs = line.nargs+1
				if line.nargs == line.maxargs then
					asm:add_line()
					line.nargs = 0
				end
			end,

			-----------------------------------------------------------------------------
			-- asm:size()
			-- Return the number of bytes
			-----------------------------------------------------------------------------
			size = function(asm)
				return asm.__code_size
			end,

			-----------------------------------------------------------------------------
			-- asm:write()
			-- Returns a string with all the lines of code, ready to print.
			-----------------------------------------------------------------------------
			write = function(asm)
				local s = ""
				for k,v in pairs(asm.__code) do
					local list = {v.label, v.clabel, v.command, v.args, v.comment}
					for k,v in pairs(list) do
						if string.len(v) > 0 then
							s = s..v
							if k == 3 or k == 4 then s = s.."\t" end
						end
					end

					s = s .. "\n"
				end
				return s
			end,

			set_instrument = function(asm, n)
				asm:place_byte(n + 64)
			end,
		} --asm = { stuff }
		asm:add_line()
		return asm
	end --asm_assembly()

	return {
		asm = {
			byte = asm_byte,
			word = asm_word,
			comment = asm_comment,
			clabel = asm_clabel,
			label = asm_label,
			assembly = asm_assembly,
		},

		driver = {
			-----------------------------------------------------------------------------
			-- check_envelope(asm)
			-- Validate this code before calling asm:write()
 			-----------------------------------------------------------------------------
			check_envelope = function(assembly)
				if assembly:size() > 255 then
					return "FamiTone allows envelopes up to 255 bytes."
				end
			end,

			-----------------------------------------------------------------------------
			-- envelope_entry(num)
			-- Given a numeric envelope entry (num), return a string formatted for this driver
			-----------------------------------------------------------------------------
			envelope_entry = function(num) return string.format("%x", (num+192)) end,

			-----------------------------------------------------------------------------
			-- envelope_end()
			-- Return this audio driver's indicator for the end of an envelope
			-----------------------------------------------------------------------------
			envelope_end = function() return string.format("%x", 127) end,
		} --driver
	}
end



-----------------------------------------------------------------------------
-- create_context()
-- A context has a configuration and a method to translate input to assembly code.
-----------------------------------------------------------------------------
local function create_context(config)
	-- TODO: Validate config

	return {
		config = config,
		input = {},
		output = "",
		outfile = io.stdout,
		assemblies = {},

		-----------------------------------------------------------------------------
		-- translate(context)
		-- Reads from context.input and writes to context.output
		-- Returns context,err
		-----------------------------------------------------------------------------
		translate = function(context)
			-----------------------------------------------------------------------------
			-- Validate and process the input as a Lua table with proper members
			-----------------------------------------------------------------------------
			local function validate_input(context)
				-----------------------------------------------------------------------------
				-- Capture commands from a channel
				-----------------------------------------------------------------------------
				local function capture_commands(context, channel)
					local function docommand(context, command)
						local asm = context.config.asm.assembly()
						local notes = {c=0, d=2, e=4, f=5, g=7, a=9, b=11}
						local n = 0

						for note in string.gmatch(command, "[cdefgab]") do
							n = 12 * channel.octave + notes[note]
						end

						for sharp in string.gmatch(command, "[cdfga]#") do
							n = n+1
						end

						for sharperror in string.gmatch(command, "[be]#") do
							error("There is no B# or E#.")
						end

						asm:place_byte(n)
						table.insert(context.assemblies, asm)
					end

					local function getcommands(context, channel)
						local asm = context.config.asm.assembly()
						asm:set_instrument(channel.instrument)
						table.insert(context.assemblies, asm)

						capture = "(@*>*<*[ivabcdefg]#*%d*>*<*%.*)"
						for command in string.gmatch(channel.commands, capture) do
							docommand(context, command, asm)
						end
					end

					if context.input.audiotype == "music" then
						for k,v in pairs(context.input.channels) do
							getcommands(context, v)
						end
					elseif context.input.audiotype == "sound" then
						getcommands(context, context.input.channels[1])
					end
				end -- capture_commands()

				assert(type(context) == "table", "context should be a table.")
				assert(type(context.input) == "table", "context.input should be a table.")

				if context.input.title then
					local err = "title should be a string."
					assert(type(context.input.title) == "string", err)

					-- Add a label for this assembly module based on title
					local asm = context.config.asm.assembly()
					local s,_ = string.gsub(context.input.title, "%s+", "_")
					-- TODO: Delete all punctuation from s
					asm:add_label(s)
					table.insert(context.assemblies, asm)
				else
					-- No title? Go with "fammlNNNNNNN"
					local asm = context.config.asm.assembly()
					math.randomseed(os.time())
					asm:add_label("famml"..tostring(math.random(0,1000000)))
					table.insert(context.assemblies, asm)
				end

				if context.input.composer then
					local err = "composer should be a string."
					assert(type(context.input.composer) == "string", err)
				end

				if context.input.programmer then
					local err = "programmer should be a string."
					assert(type(context.input.programmer) == "string", err)
				end

				if context.input.audiotype then
					local atype = context.input.audiotype
					local err = "audiotype should be \"music\" or \"sound\"."
					assert(atype == "music" or atype == "sound", err)
				else
					context.input.audiotype = "music"
				end

				if context.input.channels then
					local err = "channels should be a table."
					assert(type(context.input.channels) == "table", err)

					-----------------------------------------------------------------------------
					-- validate_channel()
					-----------------------------------------------------------------------------
					local function validate_channel(key, channel)
						local err = "channel '"..tostring(key).."' should be a table."
						assert(type(channel) == "table", err)

						if channel.octave then
							local err = "octave should be a number."
							assert(type(channel.octave) == "number", err)
							-- TODO: Shouldn't octave be validated by config?
							local err = "octave should be >= 0."
							assert(channel.octave >= 0, err)
						else
							channel.octave = 4
						end

						if channel.notelen then
							local err = "notelen should be a number."
							assert(type(channel.notelen) == "number", err)
							-- TODO: Shouldn't notelen be validated by config?
						else
							channel.notelen = 4
						end

						if channel.instrument then
							local err = "instrument should be a number."
							assert(type(channel.instrument) == "number", err)
						else
							channel.instrument = 1
						end

						if channel.commands then
							local err = "commands should be a string."
							assert(type(channel.commands) == "string", err)
							channel.commands = string.lower(channel.commands)
							capture_commands(context, channel)
						end
					end --validate_channel()

					for k,v in pairs(context.input.channels) do
						validate_channel(k,v)
					end
				end

				return context
			end -- validate_input()

			-----------------------------------------------------------------------------
			-- Write assembly to output string
			-----------------------------------------------------------------------------
			local function output_assembly(context)
				for k,asm in pairs(context.assemblies) do
					context.output = context.output..asm:write()
				end

				return context
			end --output_assembly()

			validate_input(context)
			output_assembly(context)

			return context
		end, --translate()
	}
end --create_context()



-----------------------------------------------------------------------------
-- help()
-- Just show some friendly information about the program. :)
-----------------------------------------------------------------------------
local function help()
	print("Famml! - Convert MML to assembly\n")
	print("Usage: famml input.mml -o output")
	print("   -h  See this help screen")
	print("   -o  Redirect output to a file, as opposed to standard output")
	print("   -p  Accept input from a pipe")
end


-----------------------------------------------------------------------------
-- cli()
-- cli() handles the command-line interface
-----------------------------------------------------------------------------
local function cli()
	-----------------------------------------------------------------------------
	-- checkparams(context)
	-- checkparams validates the parameters in arg
	-----------------------------------------------------------------------------
	function checkparams(context)
		for i,v in pairs(arg) do
			if v == "-h" then help() return end
			if v == "-o" then
				if i == #arg then
					return context, "Output file expected after -o\n"
				elseif v == arg[1] then
					return context, "Cannot read from and write to the same file.\n"
				end
			end
		end

		return context
	end

	-----------------------------------------------------------------------------
	-- Process the parameters, including pipe and interactive mode
	-----------------------------------------------------------------------------
	function readinput(context)
		for i,v in pairs(arg) do
			if v == "-p" then
				-- Pipe mode!
				context.input = load(io.read("*all"))
				context.input = context.input()
			elseif v == "-o" then
				if arg[i+1] then
					context.outfile = io.open(arg[i+1], "w")
					assert(context.outfile, "Could not open output file '"..arg[i+1].."'")
				end
			else
				-- All other options are checked. If this far, then arg[1] is input file.
				if i == 1 then
					local f = io.open(arg[1])
					assert(f,"Could not open input file '"..arg[1].."'. Expected input file as first argument.")
					context.input = load(f:read("*all"))
					f:close()
					context.input = context.input()
				end
			end
		end

		return context
	end

	-----------------------------------------------------------------------------
	-- Now to the meat of the function
	-----------------------------------------------------------------------------
	context = create_context(config_ca65_famitone())
	checkparams(context)
	readinput(context)
	context:translate()
	context.outfile:write(context.output)
	if not context.outfile == io.stdout then context.outfile:close() end
end



-----------------------------------------------------------------------------
-- If this script is loaded from the command line without parameters, it should just help().
-- If it is run from dofile, it should return an interface to famml
-----------------------------------------------------------------------------
if arg == nil then
	return {
		config_ca65_famitone=config_ca65_famitone,
		create_context=create_context,
	}
elseif #arg <= 0 then
	return help()
else
	return cli()
end
