{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {self,nixpkgs,flake-utils,...}:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        packages = {
          # TODO apply hardened profile from linux_latest_hardened
          debianKernel = let
            baseKernel = pkgs.linux_latest;
          in (pkgs.linuxManualConfig {
            inherit (baseKernel) src modDirVersion;
            version = "${baseKernel.version}-custom";
            
            # V doing this allows us to get vmlinux as otherwise .dev isn't generated. .dev contains the vmlinux
            # image while .out just contains the bzImage. This is bound to the presence of the flag below
            # as out supplied config contains no modules, 
            configfile = pkgs.writeText "hack_config" ((builtins.readFile ./debian-cloud-hypervisor-kernel.conf) + 
            #  ''
            #  CONFIG_EROFS_FS=y
            #  CONFIG_EROFS_FS_DEBUG=y
            #  CONFIG_EROFS_FS_XATTR=y
            #  CONFIG_EROFS_FS_POSIX_ACL=y
            #  CONFIG_EROFS_FS_SECURITY=y
            #  CONFIG_EROFS_FS_ZIP=y
            # '' ++
            ''
              CONFIG_MODULES=y
            '');
            allowImportFromDerivation = true;
          });
          default = self.packages.${system}.debianKernel;
        };
      });
}
