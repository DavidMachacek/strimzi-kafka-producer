package cz.cloudhub.kafka_producer

import org.apache.kafka.clients.producer.ProducerConfig
import org.apache.kafka.common.serialization.StringSerializer
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.kafka.core.DefaultKafkaProducerFactory
import org.springframework.kafka.core.KafkaTemplate
import org.springframework.kafka.core.ProducerFactory
import org.springframework.scheduling.annotation.EnableScheduling
import java.io.FileInputStream
import java.security.KeyStore
import java.security.cert.X509Certificate
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.KeyManagerFactory

@Configuration
@EnableScheduling
class KafkaConfig(
    @Value("\${KAFKA_BOOTSTRAP_SERVERS}") private val bootstrapServers: String,
    @Value("\${SSL_TRUSTSTORE_LOCATION}") private val truststoreLocation: String,
    @Value("\${SSL_TRUSTSTORE_PASSWORD}") private val truststorePassword: String?,
    @Value("\${SSL_KEYSTORE_LOCATION}") private val keystoreLocation: String,
    @Value("\${SSL_KEYSTORE_PASSWORD}") private val keystorePassword: String?,
    @Value("\${SSL_KEY_PASSWORD}") private val keyPassword: String?,
    @Value("\${SSL_KEYSTORE_TYPE}") private val keystoreType: String?,
    @Value("\${SSL_TRUSTSTORE_TYPE}") private val truststoreType: String?
) {

    init {
        if (truststoreType == "PKCS12") {
            println("Truststore Certificate Details:")
            printP12Details(truststoreLocation, truststorePassword ?: "")

        }
        if (keystoreType == "PKCS12") {
            println("Keystore Certificate Details:")
            printP12Details(keystoreLocation, keystorePassword ?: "")
        }
        loadTrustStore(truststoreLocation, truststorePassword ?: "")
        loadKeyStore(keystoreLocation, keystorePassword ?: "")
    }

    @Bean
    fun producerFactory(): ProducerFactory<String, String> {
        val configProps = mutableMapOf<String, Any>(
            ProducerConfig.BOOTSTRAP_SERVERS_CONFIG to bootstrapServers,
            ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG to StringSerializer::class.java,
            ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG to StringSerializer::class.java,
            "security.protocol" to "SSL",
            "ssl.keystore.location" to keystoreLocation,
            "ssl.keystore.password" to (keystorePassword ?: ""),
            "ssl.keystore.type" to (keystoreType ?: "PKCS12"),
            "ssl.truststore.location" to truststoreLocation,
            "ssl.truststore.password" to (truststorePassword ?: ""),
            "ssl.key.password" to (keyPassword ?: ""),
            "ssl.client.auth" to "required",
            "ssl.truststore.type" to (truststoreType ?: "PKCS12")
        )
        return DefaultKafkaProducerFactory(configProps)
    }

    @Bean
    fun kafkaTemplate(): KafkaTemplate<String, String> {
        return KafkaTemplate(producerFactory())
    }



    private fun printP12Details(p12FilePath: String, password: String) {
        try {
            // Load the PKCS#12 keystore
            val keyStore = KeyStore.getInstance("PKCS12")
            keyStore.load(FileInputStream(p12FilePath), password.toCharArray())

            // Iterate over the aliases in the keystore
            val aliases = keyStore.aliases()
            while (aliases.hasMoreElements()) {
                val alias = aliases.nextElement()
                println("Alias: $alias")

                // Check if the entry is a certificate
                val certificate = keyStore.getCertificate(alias)
                if (certificate is X509Certificate) {
                    println("Certificate Details:")
                    println("  Subject: ${certificate.subjectDN}")
                    println("  Issuer: ${certificate.issuerDN}")
                    println("  Serial Number: ${certificate.serialNumber}")
                    println("  Valid From: ${certificate.notBefore}")
                    println("  Valid To: ${certificate.notAfter}")
                    println("  Signature Algorithm: ${certificate.sigAlgName}")
                }

                // Check if the entry has a private key
                if (keyStore.isKeyEntry(alias)) {
                    println("Private Key is present for alias: $alias")
                }
            }
        } catch (e: Exception) {
            println("Error reading the .p12 file: ${e.message}")
            e.printStackTrace()
        }
    }


    fun loadTrustStore(trustStorePath: String, trustStorePassword: String, trustStoreType: String = "PKCS12") {
        try {
            // Load the truststore
            val trustStore = KeyStore.getInstance(trustStoreType)
            FileInputStream(trustStorePath).use { fis ->
                trustStore.load(fis, trustStorePassword.toCharArray())
            }

            // Initialize TrustManagerFactory
            val trustManagerFactory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm())
            trustManagerFactory.init(trustStore)

            // Create SSLContext
            val sslContext = SSLContext.getInstance("TLS")
            sslContext.init(null, trustManagerFactory.trustManagers, null)

            // Set the default SSLContext
            SSLContext.setDefault(sslContext)

            println("Truststore loaded successfully!")
        } catch (e: Exception) {
            e.printStackTrace()
            println("Failed to load truststore: ${e.message}")
        }
    }
    fun loadKeyStore(keyStorePath: String, keyStorePassword: String, keyStoreType: String = "PKCS12"): SSLContext {
        try {
            // Load the keystore
            val keyStore = KeyStore.getInstance(keyStoreType)
            FileInputStream(keyStorePath).use { fis ->
                keyStore.load(fis, keyStorePassword.toCharArray())
            }

            // Initialize KeyManagerFactory
            val keyManagerFactory = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm())
            keyManagerFactory.init(keyStore, keyStorePassword.toCharArray())

            // Create and initialize SSLContext
            val sslContext = SSLContext.getInstance("TLS")
            sslContext.init(keyManagerFactory.keyManagers, null, null)

            println("Keystore loaded successfully!")
            return sslContext
        } catch (e: Exception) {
            e.printStackTrace()
            throw RuntimeException("Failed to load keystore: ${e.message}")
        }
    }
}
