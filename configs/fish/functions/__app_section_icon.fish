function __app_section_icon --argument s --description 'Debian/apt Section -> single-codepoint emoji'
    # The ONE map to maintain. Sections come from `dpkg-query -W -f='${Section}'`.
    # Only Emoji_Presentation=Yes codepoints are used so they render as colour
    # glyphs in a GTK/AppKit tab label WITHOUT a VS16 selector (VS16/Nerd glyphs
    # can render as tofu there). Strip any "universe/"-style area prefix first.
    set -l sec (string replace -r '.*/' '' -- $s)
    switch $sec
        case editors;                       echo 📝
        case vcs;                           echo 🌿
        case python;                        echo 🐍
        case ruby;                          echo 💎
        case perl;                          echo 🐪
        case php;                           echo 🐘
        case java;                          echo ☕
        case javascript;                    echo 📦
        case rust;                          echo 🦀
        case haskell lisp ocaml;            echo 🧩
        case interpreters;                  echo 📜
        case devel libdevel;                echo 🔨
        case admin;                         echo 🔧
        case utils cli-mono misc;           echo 🧰
        case shells;                        echo 🐚
        case net comm;                      echo 📡
        case web httpd;                     echo 🌐
        case mail;                          echo 📧
        case news;                          echo 📰
        case database;                      echo 💽
        case science;                       echo 🔬
        case math gnu-r;                    echo 🧮
        case electronics embedded hamradio; echo 🔌
        case graphics;                      echo 🎨
        case video;                         echo 🎬
        case sound;                         echo 🔊
        case text;                          echo 📄
        case doc;                           echo 📖
        case fonts;                         echo 🔤
        case games;                         echo 🎲
        case kernel;                        echo 🐧
        case libs oldlibs;                  echo 📚
        case localization;                  echo 🌍
        case tex;                           echo 📐
        case x11 gnome kde xfce;            echo 🪟
        case otherosfs;                     echo 💾
        case metapackages tasks;            echo 📦
        case '*';                           echo ''   # unknown -> caller falls back
    end
end
