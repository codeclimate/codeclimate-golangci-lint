# Code Climate golangci Engine

`codeclimate-golangci` is a Code Climate engine that executes [`golangci-lint`](https://github.com/golangci/golangci-lint) and reports findings to Code Climate.

### Installation & Usage

1. If you haven't already, [install the Code Climate CLI](https://github.com/codeclimate/codeclimate).
2. Run `codeclimate engines:enable golangci`. This command both installs the engine and enables it in your `.codeclimate.yml` file.
3. Configure `golangci-lint` through its [configuration file](https://golangci-lint.run/usage/configuration/).
3. You're ready to analyze! Browse into your project's folder and run `codeclimate analyze`.

### Configuration

You can enable the engine using your `.codeclimate.yml`:

```yaml
engines:
  golangci:
    enabled: true
```

Then, configure `golangci-lint` through its [configuration file](https://golangci-lint.run/usage/configuration/).

### Need help?

For help with `codeclimate-golangci`, please open an issue on this repository.

### License

```
Copyright (c) 2015 Gympass.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

```
