require "../spec_helper"

describe "error locations" do
  it do
    exc = expect_raises(Crinja::UndefinedError, "non_existing.prop is undefined.") do
      render <<-'TPL'
        <html>
          <div>{{ non_existing.prop }}</div>
        </div>
        TPL
    end

    exc.template.should_not be_nil
    exc.template.not_nil!.filename.should be_nil
    exc.variable_name.should eq "non_existing.prop"

    exc.location_start.should eq({2, 11})
    exc.location_end.should eq({2, 28})
    exc.message.should contain "template: <string>"
    exc.message.should contain "\n 2 |   <div>{{ non_existing.prop }}</div>" \
                               "\n ⚡ |           ^~~~~~~~~~~~~~~~~\n"
  end
end
