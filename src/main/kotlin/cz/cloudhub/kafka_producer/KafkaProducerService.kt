package cz.cloudhub.kafka_producer

import org.springframework.beans.factory.annotation.Value
import org.springframework.kafka.core.KafkaTemplate
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Service
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.io.FileInputStream
import java.security.KeyStore
import java.security.cert.X509Certificate

@Service
class KafkaProducerService(
    private val kafkaTemplate: KafkaTemplate<String, String>,
    @Value("\${KAFKA_PRODUCER_TOPICNAME}") private val topicName: String,
    @Value("\${KAFKA_PRODUCER_TOPICMESSAGE_PREFIX}") private val topicPrefix: String
) {

    private var messageNumber = 0

    @Scheduled(fixedRateString = "\${message.scheduler.fixedRate}")
    fun sendMessages() {
        messageNumber ++
        val currentDateTime = LocalDateTime.now()
        val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
        val prettyDateTime = currentDateTime.format(formatter)
        val message = topicPrefix + " (topicName=$topicName, number=$messageNumber, UUID = ${java.util.UUID.randomUUID()}, generatedAt = $prettyDateTime)"
        sendMessage(topicName, message)
    }

    fun sendMessage(topic: String, message: String) {
        println("messageSend - topic: '$String', message: '$message'")
        kafkaTemplate.send(topic, message)
    }

}
