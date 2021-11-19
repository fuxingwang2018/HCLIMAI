from tensorflow.keras import layers, models

def model_discriminator(nx, nz, channels, batch_size):

    inputs = layers.Input(shape=(nz, nx, channels), batch_size=batch_size, name='high-res-input')
        
    model = layers.Conv2D(filters = 16, kernel_size = 7, strides = 1, padding = "same")(inputs)
    model = layers.LeakyReLU(alpha = 0.2)(model)
    
    model = discriminator_block(model, 16, 3, 2)
    model = discriminator_block(model, 32, 3, 1)
    model = discriminator_block(model, 32, 3, 2)
    model = discriminator_block(model, 64, 3, 1)
    model = discriminator_block(model, 64, 3, 2)
    model = discriminator_block(model, 128, 3, 1)
    model = discriminator_block(model, 128, 3, 2)
    
    model = layers.Flatten()(model)
    model = layers.Dense(1024)(model)
    model = layers.LeakyReLU(alpha = 0.2)(model)

    model = layers.Dense(1)(model)
    model = layers.Activation('sigmoid')(model) 
    
    model = models.Model(inputs=inputs, outputs = model, name='Discriminator')


    print(model.summary())
    
    return model


def discriminator_block(model, filters, kernel_size, strides):
        
    model = layers.Conv2D(filters = filters, kernel_size = kernel_size, strides = strides, padding = "same")(model)
    model = layers.BatchNormalization(momentum = 0.5)(model)
    model = layers.LeakyReLU(alpha = 0.2)(model)
    
    return model