## LaAlbiceleste GRUB Theme

This theme is partly based on the following themes:

- "Persona 3 Reload GRUB theme" https://github.com/RumIT802/Persona-3-Reload-Grub-Theme
- "Catppuccin for Grub" https://github.com/catppuccin/grub
- "CyberGRUB-2077" https://github.com/adnksharp/CyberGRUB-2077

The background image is from "walls-catppuccin-mocha" https://github.com/orangci/walls-catppuccin-mocha  
If someone knows the original artist, please let me know, so that I can give proper credit.

<img width="1920" height="1080" alt="preview" src="https://github.com/user-attachments/assets/943a9d12-5bdf-48d2-a521-ffe8cdee0fdf" />

I made and tested this theme for a 1920x1080 resolution.

### How to install

#### Option A — Install script (recommended)

```bash
chmod +x install.sh
sudo ./install.sh
```

To preview what it would do without making any changes:

```bash
sudo ./install.sh --dry-run
```

To uninstall:

```bash
sudo ./install.sh --uninstall
```

#### Option B — Manual install

1. Extract the theme to `/boot/grub/themes/`
2. Edit `/etc/default/grub`. Find the line starting with `#GRUB_THEME` and change it to:
   ```
   GRUB_THEME=/boot/grub/themes/la_albiceleste/theme.txt
   ```
3. Run `sudo update-grub`
