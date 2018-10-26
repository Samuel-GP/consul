class UserImporter

  require 'roo'
  require 'spreadsheet'

  def self.definir_columnas
    {
      numero_documento: 7,
      letra_documento: 8,
      tipo_documento: 10,
      fecha_nacimiento: 13,
      codigo_postal: 24,
      nombre: 5,
      apellido1: 1,
      apellido1_particula: 2,
      apellido2: 3,
      apellido2_particula: 4
    }
  end

  def self.importar(columna)
    rows_total = 1
    rows_errors = 0
    source = "#{Rails.root}/padron.xls"
    if File.exist?(source)
      if source.split('.').last == 'xlsx'
        xls = Roo::Spreadsheet.open(source)
        xls.each_row_streaming do |row|
          hash_user = {
            numero_documento: "#{row[columna[:numero_documento]].value&.to_i}#{row[columna[:letra_documento]]&.value}",
            tipo_documento: row[columna[:tipo_documento]]&.value&.to_i,
            fecha_nacimiento: row[columna[:fecha_nacimiento]]&.value&.to_date,
            codigo_postal: row[columna[:codigo_postal]]&.value&.to_i,
            nombre: row[columna[:nombre]]&.value,
            apellido1: "#{row[columna[:apellido1]]&.value}#{row[columna[:apellido1_particula]]&.value}"&.strip,
            apellido2: "#{row[columna[:apellido2]]&.value}#{row[columna[:apellido2_particula]]&.value}"&.strip
          }
          rows_total += 1
          if hash_user[:numero_documento].nil? or hash_user[:tipo_documento].nil? or hash_user[:fecha_nacimiento].nil? or hash_user[:codigo_postal].nil?
            rows_errors += 1
          else
            insertar(hash_user)
          end
        end
      elsif source.split('.').last == 'xls'
        xls = Spreadsheet.open(source)
        xls.worksheets.first.rows.each do |row|
          hash_user = {
            numero_documento: "#{row[columna[:numero_documento]]&.to_i}#{row[columna[:letra_documento]]}",
            tipo_documento: row[columna[:tipo_documento]]&.to_i,
            fecha_nacimiento: row[columna[:fecha_nacimiento]]&.to_date,
            codigo_postal: row[columna[:codigo_postal]]&.to_i,
            nombre: row[columna[:nombre]]&.to_s,
            apellido1: "#{row[columna[:apellido1]]}#{row[columna[:apellido1_particula]]}"&.strip,
            apellido2: "#{row[columna[:apellido2]]}#{row[columna[:apellido2_particula]]}"&.strip
          }
          rows_total += 1
          if hash_user[:numero_documento].nil? or hash_user[:tipo_documento].nil? or hash_user[:fecha_nacimiento].nil? or hash_user[:codigo_postal].nil?
            rows_errors += 1
          else
            insertar(hash_user)
          end
        end
      end
      "Se han encontrado #{rows_total-1} usuarios y #{rows_errors} error(es)."
    else
      "No se ha encontrado el fichero fuente."
    end
  end

  def self.insertar(hash_user)
    lcr = LocalCensusRecord.find_or_initialize_by(document_number: hash_user[:numero_documento])
    lcr.document_type = hash_user[:tipo_documento]
    lcr.date_of_birth = hash_user[:fecha_nacimiento]
    lcr.postal_code = hash_user[:codigo_postal]
    lcr.save
  end

  def self.crear_usuarios
    LocalCensusRecord.all.each do |lc|
      u = User.find_or_initialize_by(username: lc.document_number)
      u.email = "#{lc.document_number}@guadassuar.es"
      u.confirmed_at = Date.today
      u.username = "#{lc.document_number}"
      u.document_number = "#{lc.document_number}"
      u.document_type = "#{lc.document_type}"
      u.residence_verified_at = Date.today
      u.verified_at = Date.today
      u.date_of_birth = lc.date_of_birth
      u.password = u.password_confirmation = lc.date_of_birth.strftime("%d/%m/%Y")
      u.terms_of_service = "1"
      u.save
      puts u.errors.inspect
    end
  end


end