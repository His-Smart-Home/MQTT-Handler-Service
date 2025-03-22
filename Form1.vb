Imports Microsoft.Win32
Imports MQTTnet
Imports MQTTnet.Client
Imports MQTTnet.Client.Connecting
Imports MQTTnet.Client.Options
Imports MQTTnet.Client.Receiving
Imports System.Text
Imports System.Diagnostics


Public Class Form1

    Private mqttClient As IMqttClient
    Private mqttOptions As IMqttClientOptions

    Private Sub Form1_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        Me.Visible = False
        Me.ShowInTaskbar = False
        Me.WindowState = FormWindowState.Minimized
        Try
            ' Read MQTT settings from the registry
            Dim key = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry32) _
                     .OpenSubKey("Software\His Smart Home\MQTT-Listener")
            If key Is Nothing Then
                MessageBox.Show("Registry key not found.")
                Return
            End If

            Dim server = key.GetValue("Server", "").ToString()
            Dim port = Convert.ToInt32(key.GetValue("Port", 1883))
            Dim username = key.GetValue("Username", "").ToString()
            Dim password = key.GetValue("Password", "").ToString()
            Dim topic = key.GetValue("Topic", "").ToString()
            Dim clientId = key.GetValue("ClientId", "vbnet-client-" & Guid.NewGuid().ToString()).ToString()
            Dim urlToOpen = key.GetValue("UrlToOpen", "").ToString()
            Dim useTls = Convert.ToBoolean(key.GetValue("UseTLS", 0))

            ' Create MQTT client
            Dim factory = New MqttFactory()
            mqttClient = factory.CreateMqttClient()

            ' Set up options
            Dim builder = New MqttClientOptionsBuilder() _
                .WithClientId(clientId) _
                .WithTcpServer(server, port)

            If Not String.IsNullOrEmpty(username) Then
                builder = builder.WithCredentials(username, password)
            End If

            If useTls Then
                builder = builder.WithTls()
            End If

            mqttOptions = builder.Build()

            ' Set message handler
            mqttClient.ApplicationMessageReceivedHandler = New MqttApplicationMessageReceivedHandlerDelegate(
            Sub(msg)
                Dim payload As String = Encoding.UTF8.GetString(msg.ApplicationMessage.Payload)

                If Not String.IsNullOrWhiteSpace(urlToOpen) Then
                    Dim finalUrl As String = urlToOpen & Uri.EscapeDataString(payload)
                    Process.Start(finalUrl)
                End If
            End Sub)

            ' Connect and subscribe
            mqttClient.ConnectedHandler = New MqttClientConnectedHandlerDelegate(
            Async Sub(args)
                Await mqttClient.SubscribeAsync(topic)
                MessageBox.Show("Connected and subscribed to: " & topic)
            End Sub)


            mqttClient.ConnectAsync(mqttOptions)

        Catch ex As Exception
            MessageBox.Show("Error: " & ex.Message)
        End Try
    End Sub

End Class
