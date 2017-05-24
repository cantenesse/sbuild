require 'open3'

def self.safe_retry(cmd, tries=3)
    begin
        status, output = system_safe(cmd)
    rescue
        if (tries -= 1) > 0
            sleep 5
            retry unless (tries).zero?
        else
            raise "Build failed"
        end
    end

    return status

end
def self.system_safe(cmd)
    cmd_sanitized = get_sanitized_cmd(cmd)
    puts "Executing command: #{cmd_sanitized}"

    stdout, stderr, status = Open3.capture3(cmd)

    if not status.success?
        raise "Build failed"
    end

    return [status.success?, stdout]

end

def self.get_secret(key, subkey)
    cmd = "vault read -field=#{subkey} #{key}"
    status, secret = system_safe(cmd)
	secret = secret.strip
end

def self.revoke_lease(lease_id)
	cmd = "vault revoke #{lease_id}"
	safe_retry(cmd)
end

def self.get_sanitized_cmd(cmd)
    secret_fields = ["AWS_ACCESS_KEY_ID",
                     "AWS_SECRET_ACCESS_KEY",
                     "password",
                     "aws_access_key_id",
                     "aws_secret_access_key",
                     "aws_access_key",
                     "aws_secret_key",
                     "access_key",
                     "secret_key",
                     "account_access_key",
                     "account_secret_key",
                     "aws.accessKeyId",
                     "aws.secretKey",
                     "jwtsecret",
                     "master_access_key",
                     "master_secret_key",
                     "github_password"]

    cmd = cmd.gsub(/\s+/m, ' ').strip.split(" ")
    replace = cmd.grep(Regexp.union(secret_fields))
    unless replace.empty?
        replace = Set.new replace
        cmd.collect! {|e| (replace.include? e) ? '<secret>': e}
    end
    cmd = cmd.join(' ')
end