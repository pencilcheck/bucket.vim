module Bucket
  module VIM
    def self.has_syntax?
      ::VIM::evaluate('has("syntax")').to_i != 0
    end

    def self.exists? str
      ::VIM::evaluate(%{exists("#{str}")}).to_i != 0
    end

    def self.has_conceal?
      ::VIM::evaluate('has("conceal")').to_i != 0
    end

    def self.pwd
      ::VIM::evaluate 'getcwd()'
    end

    def self.wild_ignore
      exists?('&wildignore') && ::VIM::evaluate('&wildignore').to_s
    end

    # Execute cmd, capturing the output into a variable and returning it.
    def self.capture cmd
      ::VIM::command 'silent redir => g:command_t_captured_output'
      ::VIM::command cmd
      ::VIM::command 'silent redir END'
      ::VIM::evaluate 'g:command_t_captured_output'
    end

    # Escape a string for safe inclusion in a Vim single-quoted string
    # (single quotes escaped by doubling, everything else is literal)
    def self.escape_for_single_quotes str
      str.gsub "'", "''"
    end
  end
end
