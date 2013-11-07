task :install, [:install_prefix] do |t, args|
  args.with_defaults(:install_prefix => '/usr')
  puts "Installing to #{args.install_prefix}"
  sh "mkdir -p #{args.install_prefix}/share/doc/gister"
  sh "chmod 755 gister.sh"
  sh "cp gister.sh #{args.install_prefix}/bin/gister"
  sh "chmod 644 man/gister.1"
  sh "gzip -c man/gister.1 > #{args.install_prefix}/share/man/man1/gister.1.gz"
  sh "chmod 644 README.md"
  sh "cp README.md #{args.install_prefix}/share/doc/gister/README.md"
end
