{ pkgs, ... }:

let
  firefoxProfileName = "JuliansDefaultProfile";
in
{
  programs.firefox = {
    enable = true;
    languagePacks = [
      "en-US"
      "de"
      "fi"
    ];

    policies = {
      DisableFirefoxStudies = true;
      DisableTelemetry = true;
      AutofillCreditCardEnabled = false;
      Cookies = {
        Behavior = "reject-foreign";
        Locked = true;
      };
      DisableFirefoxAccounts = true;
      DisablePocket = true;
      DisableMasterPasswordCreation = true;
      EnableTrackingProtection = {
        Value = true;
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
        Locked = true;
      };
      HttpsOnlyMode = "force_enabled";
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      DisableProfileImport = true;
      FirefoxHome = {
        Search = true;
        TopSites = false;
        SponsoredTopSites = false;
        Highlights = false;
        Pocket = false;
        SponsoredPocket = false;
        Snippets = false;
        Locked = true;
      };
      SanitizeOnShutdown = {
        Cache = true;
        Cookies = true;
        Downloads = false;
        FormData = false;
        History = false;
        Sessions = false;
        SiteSettings = false;
        OfflineApps = true;
        Locked = true;
      };
      Handlers.mimeTypes."application/pdf".ask = true;
      #set firefox settings through policies so that they are grayed out in UI and I can see which settings are set using home-manager and which not
      Preferences = {
        "intl.regional_prefs.use_os_locales" = {
          Value = true;
          Status = "locked";
        };
        "browser.download.useDownloadDir" = {
          Value = false;
          Status = "locked";
        };
        "browser.ctrlTab.sortByRecentlyUsed" = {
          Value = true;
          Status = "locked";
        };
        "browser.tabs.inTitlebar" = {
          Value = 0;
          Status = "locked";
        };
        "privacy.globalprivacycontrol.enabled" = {
          Value = true;
          Status = "locked";
        };
        "browser.urlbar.trimURLs" = {
          Value = false;
          Status = "locked";
        };
        "browser.urlbar.showSearchTerms.enabled" = {
          Value = false;
          Status = "locked";
        };
      };
    };

    profiles."${firefoxProfileName}" = {
      containers = {
        partanengroup = {
          color = "green";
          icon = "briefcase";
          id = 1;
        };
        netflix = {
          color = "red";
          icon = "chill";
          id = 2;
        };
        disneyplus = {
          color = "blue";
          icon = "chill";
          id = 3;
        };
        amazon = {
          color = "orange";
          icon = "cart";
          id = 4;
        };
        meta = {
          color = "yellow";
          icon = "fingerprint";
          id = 5;
        };
        ebay = {
          color = "turquoise";
          icon = "cart";
          id = 6;
        };
        kleinanzeigen = {
          color = "pink";
          icon = "cart";
          id = 7;
        };
        robertsspaceindustries = {
          color = "purple";
          icon = "chill";
          id = 8;
        };
      };
      containersForce = true;

      #as of now I don't declaratively configure extension settings yet, support for it has been added recently though
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        multi-account-containers
        keepassxc-browser
        floccus
        ublock-origin
      ];

      search = {
        default = "ddg";
        engines = {
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];

            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };

          "NixOS options" = {
            urls = [
              {
                template = "https://search.nixos.org/options";
                params = [
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];

            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@no" ];
          };

          "NixOS Wiki" = {
            urls = [ { template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; } ];
            icon = "https://wiki.nixos.org/favicon.ico";
            updateInterval = 24 * 60 * 60 * 1000; # every day
            definedAliases = [ "@nw" ];
          };

          "bing".metaData.hidden = true;
          "google".metaData.alias = "@g"; # builtin engines only support specifying one additional alias
          "wikipedia".metaData.alias = "@w";
        };
        force = true;
        order = [
          "ddg"
          "wikipedia"
          "Nix Packages"
          "NixOS options"
          "NixOS Wiki"
        ];
      };

      #these settings cannot be set through Preferences policy
      settings = {
        "extensions.autoDisableScopes" = 0; # activate extensions defined above by default
        "privacy.donottrackheader.enabled" = true;
      };
    };
  };
  stylix.targets.firefox.profileNames = [
    firefoxProfileName
  ];

  programs.thunderbird = {
    enable = true;

    profiles."JuliansDefaultProfile" = {
      isDefault = true;

      withExternalGnupg = true;
      settings = {
        "mail.tabs.drawInTitlebar" = false;
        "network.cookie.cookieBehavior" = 1;
        "privacy.donottrackheader.enabled" = true;
        "mail.e2ee.auto_enable" = true;
        "mail.e2ee.auto_disable" = true;
        "mail.e2ee.notify_on_auto_disable" = true;
        "mailnews.default_sort_order" = 1;
        "calendar.alarms.show" = false;
        "calendar.alarms.showmissed" = false;
        "calendar.alarms.playsound" = false;
        "calendar.notifications.times" = "-PT30M";
      };
    };
  };
}
