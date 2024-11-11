import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'
import serviceAccount from '../service-account.json' with { type: 'json' }

interface Message {
  id: number  
  user_id: string
  room_id: string
  content: string
  created_at: string
}

interface WebhookPayload {
  type: 'INSERT'
  table: string
  record: Message
  schema: 'public'
}

interface Receiver {
  username: string
  fcm_token: string
}

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

const logInfo = (message: string, data?: any) => {
  console.log(`[INFO] ${message}`, data ? JSON.stringify(data) : '')
}

const logError = (message: string, error: any) => {
  console.error(`[ERROR] ${message}`, error)
}

const sentNotifications = new Set<string>()
setInterval(() => sentNotifications.clear(), 5 * 60 * 1000)

Deno.serve(async (req) => {
  try {
    const payload: WebhookPayload = await req.json()
    logInfo('Gelen webhook payload:', payload)

    if (payload.type !== 'INSERT' || payload.table !== 'messages' || !payload.record) {
      throw new Error('Invalid webhook payload: Unexpected format')
    }

    const messageData = payload.record
    logInfo('Message data:', messageData)

    // Chat room'u bul - name'i de seçiyoruz
    const { data: room, error: roomError } = await supabase
      .from('chat_rooms')
      .select('participants, is_group, name')
      .eq('id', messageData.room_id)
      .single()

    if (roomError) {
      logError('Chat room hatası:', roomError)
      throw new Error(`Chat room bulunamadı: ${messageData.room_id}`)
    }

    if (!room?.participants?.length) {
      return new Response(
        JSON.stringify({ message: 'Odada katılımcı yok' }),
        { headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { data: receivers, error: receiversError } = await supabase
      .from('profiles')
      .select('username, fcm_token')
      .in('id', room.participants)
      .neq('id', messageData.user_id)

    if (receiversError) {
      logError('Alıcılar hatası:', receiversError)
      throw new Error('Alıcılar bulunamadı')
    }

    if (!receivers?.length) {
      return new Response(
        JSON.stringify({ message: 'Odada başka üye yok' }),
        { headers: { 'Content-Type': 'application/json' } }
      )
    }

    const uniqueReceivers: Receiver[] = Array.from(
      new Map(
        receivers
          .filter(r => r.fcm_token)
          .map(r => [r.fcm_token, r])
      ).values()
    );

    logInfo('Unique token sahibi alıcı sayısı:', uniqueReceivers.length)

    const { data: sender, error: senderError } = await supabase
      .from('profiles')
      .select('username')
      .eq('id', messageData.user_id)
      .single()

    if (senderError) {
      logError('Gönderici hatası:', senderError)
      throw new Error('Gönderici bulunamadı')
    }

    const accessToken = await getAccessToken({
      clientEmail: serviceAccount.client_email,
      privateKey: serviceAccount.private_key,
    })

    const notificationPromises = uniqueReceivers.map(async receiver => {
      try {
        const notificationId = `${messageData.id}_${receiver.fcm_token}`
        
        if (sentNotifications.has(notificationId)) {
          logInfo(`Bildirim zaten gönderilmiş: ${notificationId}`)
          return { 
            skipped: true, 
            receiver: receiver.username,
            reason: 'Duplicate notification'
          }
        }

        const notificationPayload = {
          message: {
            token: receiver.fcm_token,
            notification: {
              title: room.is_group ? `${sender?.username} (${room.name})` : sender?.username || 'Yeni Mesaj',
              body: messageData.content,
            },
            android: {
              priority: "HIGH",
              notification: {
                clickAction: "FLUTTER_NOTIFICATION_CLICK",
                channelId: "high_importance_channel",
                sound: "default"
              }
            },
            data: {
              messageId: messageData.id.toString(),
              roomId: messageData.room_id,
              senderId: messageData.user_id,
              type: "chat_message",
              isGroup: room.is_group.toString(),
              roomName: room.name || ''
            }
          }
        }

        logInfo('Gönderilen notification payload:', notificationPayload)

        const response = await fetch(
          `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${accessToken}`,
            },
            body: JSON.stringify(notificationPayload),
          }
        )

        if (!response.ok) {
          const errorData = await response.json()
          logError('FCM API Error:', errorData)
          throw new Error(`FCM API Error: ${errorData.error?.message || 'Unknown error'}`)
        }

        const result = await response.json()
        sentNotifications.add(notificationId)
        
        logInfo(`Bildirim gönderildi - Alıcı: ${receiver.username}`, result)
        return result
      } catch (error) {
        logError(`Bildirim gönderimi hatası - Alıcı: ${receiver.username}`, error)
        return { 
          error: error instanceof Error ? error.message : String(error), 
          receiver: receiver.username 
        }
      }
    })

    const results = await Promise.all(notificationPromises)
    logInfo('Tüm bildirimler tamamlandı:', results)

    return new Response(JSON.stringify({ success: true, results }), {
      headers: { 'Content-Type': 'application/json' },
    })

  } catch (error) {
    logError('Genel hata:', error)
    return new Response(
      JSON.stringify({ 
        error: error instanceof Error ? error.message : 'Unknown error',
        details: error instanceof Error ? error.stack : error
      }),
      { 
        headers: { 'Content-Type': 'application/json' },
        status: 400 
      }
    )
  }
})

function getAccessToken({
  clientEmail,
  privateKey,
}: {
  clientEmail: string
  privateKey: string
}): Promise<string> {
  return new Promise((resolve, reject) => {
    const jwtClient = new JWT({
      email: clientEmail,
      key: privateKey,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    jwtClient.authorize((err, tokens) => {
      if (err) {
        reject(err)
        return
      }
      resolve(tokens!.access_token!)
    })
  })
}