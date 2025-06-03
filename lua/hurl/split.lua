local Split = require('nui.split')
local event = require('nui.utils.autocmd').event

local split = Split({
	relative = 'editor',
	position = _HURL_GLOBAL_CONFIG.split_position,
	size = _HURL_GLOBAL_CONFIG.split_size,
	buf_options = { filetype = 'markdown' },
})

local utils = require('hurl.utils')

local M = {}

-- Show content in a split
---@param data table
---   - body string
---   - headers table
---@param type 'json' | 'html' | 'xml' | 'text' | 'markdown'
M.show = function(data, type)
	local function quit()
		vim.cmd(_HURL_GLOBAL_CONFIG.mappings.close)
		split:unmount()
	end
	-- mount/open the component
	split:mount()

	if _HURL_GLOBAL_CONFIG.auto_close then
		-- unmount component when buffer is closed
		split:on(event.BufLeave, function()
			quit()
		end)
	end

	local output_lines = {}

	if type == 'markdown' then
		-- For markdown, we just use the body as-is
		output_lines = vim.split(data.body, '\n')
	else
		-- Add curl command
		table.insert(output_lines, data.curl_command or 'N/A')
		table.insert(output_lines, '')

		-- Add request information
		local response_time = tonumber(data.response_time) or 0
		table.insert(output_lines,
			string.format('Method: %s    Status: %s    Time: %.2f ms', data.method or 'Method: N/A', data.status or 'N/A',
				response_time))
		table.insert(output_lines, '')

		-- Add headers
		if data.headers then
			for key, value in pairs(data.headers) do
				table.insert(output_lines, string.format('%s: %s', key, value))
			end
		else
			table.insert(output_lines, 'Headers: N/A')
		end

		-- Add body
		table.insert(output_lines, '')
		local content = utils.format(data.body, type)
		if content then
			for _, line in ipairs(content) do
				table.insert(output_lines, line)
			end
		else
			table.insert(output_lines, 'Body: N/A')
		end
	end

	-- Set content
	vim.api.nvim_buf_set_lines(split.bufnr, 0, -1, false, output_lines)

	split:map('n', _HURL_GLOBAL_CONFIG.mappings.close, function()
		quit()
	end)
end

M.clear = function()
	-- Check if split is open
	if not split.winid then
		return
	end

	-- Clear the buffer and add `Processing...` message with the current Hurl command
	vim.api.nvim_buf_set_lines(split.bufnr, 0, -1, false, {
		'Processing...',
		'',
		'# Hurl Command',
		'',
		'```sh',
		_HURL_GLOBAL_CONFIG.last_hurl_command or 'N/A',
		'```',
	})
end

return M
