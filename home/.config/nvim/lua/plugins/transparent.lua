return {
  {
    "xiyaowong/transparent.nvim",
    lazy = false,
    config = function()
      require("transparent").setup({
        extra_groups = {
          "NormalFloat",
          "FloatBorder",
          "NeoTreeNormal",
          "NeoTreeNormalNC",
          "BufferLineBackground",
          "BufferLineFill",
        },
      })
    end,
  },
}
