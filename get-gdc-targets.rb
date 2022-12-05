def get_gdc_targets
    cmd = "ls -1 /usr/bin/*-gdc"
    IO.popen(cmd) do |r|
        lines = r.readlines
        return nil if lines.empty?
  
        targets = []
        for line in lines
            target = line.delete_suffix("\n").delete_prefix("/usr/bin/")
            targets.push target
        end
        return targets
    end
rescue
    return nil
end

if __FILE__ == $0
    pp get_gdc_targets
end
