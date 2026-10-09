# To use this install script run these following commands in your terminal:

    1. Download the Main script to any dir
        
        curl -L -O https://github.com/G00380316/Mac_Install/raw/main/install.sh
    
    2. Use chmod to give necessary permissions to run script
        
        chmod +x install.sh

    3. Run the Script
       
        ./install.sh



# After the script (Neovim)

    - Sign in to GitHub Copilot once, from any code file in Neovim:

        :LspCopilotSignIn

    - Notebooks (.ipynb) open as Markdown through jupytext, and <leader>n runs a
      cell. The script sets up the Python environment this needs at
      ~/.local/share/nvim/python-host; to use a project's own libraries in a
      notebook, pick that project's kernel from the Notebook Actions menu.
