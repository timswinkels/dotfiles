return {
    {
    'neovim/nvim-lspconfig',
    },
    {
        'hrsh7th/nvim-cmp',
        dependencies = {
          'hrsh7th/cmp-nvim-lsp',
          'hrsh7th/cmp-buffer',
          'hrsh7th/cmp-path',
          'hrsh7th/cmp-cmdline',
        },
    },
    {
        'mason-org/mason-lspconfig.nvim',
        opts = {},
        dependencies = {
            {
                'mason-org/mason.nvim',
                opts = {}
            },
        },
    },
}
