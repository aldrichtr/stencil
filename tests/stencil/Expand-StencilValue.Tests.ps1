
Describe 'Private function Expand-StencilValue' {
    Context 'When a token is present in the Value' -Foreach @(
        @{
            StencilText = '${env.Greeting} ${env.Subject}'
            Expected = 'Hello World'
            Data = [PSCustomObject]@{
                PSTypeName = 'Stencil.JobInfo'
                env = @{
                    Greeting = 'Hello'
                    Subject  = 'World'
                }
            }
        }
        @{
            StencilText = '${env.Greeting} ${not.present} ${env.Subject}'
            Expected    = 'Hello ${not.present} World'
            Data        = [PSCustomObject]@{
                PSTypeName = 'Stencil.JobInfo'
                env = @{
                    Greeting = 'Hello'
                    Subject  = 'World'
                }
            }

        }
    ) {
        BeforeAll {
            $result = $StencilText | Expand-StencilValue -Data $Data
        }

        It "Should Replace the tokens in the text '<StencilText>'" {
            $result | Should -be $Expected
        }
    }
}
