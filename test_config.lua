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

return config_ca65_famitone()
